/**********************************************************************
FORMULA NAME      : GB_CMP_NEW_HIRE_RETROFIT
CREATED_BY        : IT-GLOBAL
CREATION_DATE     : (segun version original)
LAST_UPDATE_DATE  : 25 de Agosto del 2026
FORMULA TYPE      : Compensation Default and Override
DESCRIPTION       : Identifica si el colaborador es New Hire para R1, usando
                    ventana de 5 meses antes del cierre del plan. Excluye
                    transferencias e intercompany leyendo el ACTION_REASON_CODE
                    de la asignacion anterior terminada, localizada iterando
                    el array PER_HIST_ASG_* y filtrando por asignacion
                    distinta a la actual cuyo rango cubre el dia previo a
                    L_HIRE_DATE. Codigos de exclusion R1 confirmados:
                    28, C28, 00, U00, 115.
                    REHIRE_WK es codigo receptor: no se lee, se excluye por
                    ausencia de asignacion anterior con reason de exclusion.
**********************************************************************/

INPUTS ARE
CMP_IV_PLAN_EXTRACTION_DATE (text),
CMP_IV_PLAN_START_DATE (text),
CMP_IV_PLAN_END_DATE (text)

DEFAULT FOR CMP_IV_PLAN_EXTRACTION_DATE IS '4012/01/01'
DEFAULT FOR CMP_IV_PLAN_START_DATE IS '1900/01/01'
DEFAULT FOR CMP_IV_PLAN_END_DATE IS '4012/01/01'
DEFAULT FOR PER_ASG_EFFECTIVE_START_DATE IS '1981/05/15' (date)
DEFAULT FOR PER_PER_LATEST_REHIRE_DATE IS '1901/01/01' (date)
DEFAULT FOR PER_ASG_REL_ORIGINAL_DATE_OF_HIRE IS '1901/01/01' (date)
DEFAULT FOR PER_ASG_ACTION_REASON_CODE IS 'N/A'

DEFAULT_DATA_VALUE FOR PER_HIST_ASG_EFFECTIVE_START_DATE IS '1900/01/01' (date)
DEFAULT_DATA_VALUE FOR PER_HIST_ASG_EFFECTIVE_END_DATE IS '4712/12/31' (date)
DEFAULT_DATA_VALUE FOR PER_HIST_ASG_ASSIGNMENT_ID IS 0

L_DEFAULT_VALUE = 'N'
L_NEW_HIRE = 'N'
L_ASG_ID_ANTERIOR = 0
L_REASON_CODE = 'N/A'
L_IDX = 0
L_TOTAL_FILAS = 0

HR_EXTRACT_DATE = TO_DATE(CMP_IV_PLAN_EXTRACTION_DATE, 'YYYY/MM/DD')
L_PL_START_DATE = TO_DATE(CMP_IV_PLAN_START_DATE, 'YYYY/MM/DD')
L_PL_END_DATE   = TO_DATE(CMP_IV_PLAN_END_DATE, 'YYYY/MM/DD')

l_log = SET_LOG('*** INICIO GB_CMP_NEW_HIRE_RETROFIT R1 ***')
l_log = SET_LOG('Fecha extraccion: ' || TO_CHAR(HR_EXTRACT_DATE))
l_log = SET_LOG('Fecha inicio plan: ' || TO_CHAR(L_PL_START_DATE))
l_log = SET_LOG('Fecha fin plan: ' || TO_CHAR(L_PL_END_DATE))

L_CTX_ASG = GET_CONTEXT(HR_ASSIGNMENT_ID, -1)
l_log = SET_LOG('Assignment ID actual (contexto interno): ' || TO_CHAR(L_CTX_ASG))

L_HIRE_DATE = PER_ASG_EFFECTIVE_START_DATE
L_ORIGINAL_HIRE_DATE = PER_ASG_REL_ORIGINAL_DATE_OF_HIRE
L_LATEST_REHIRE_DATE = PER_PER_LATEST_REHIRE_DATE

l_log = SET_LOG('Assignment Start Date: ' || TO_CHAR(L_HIRE_DATE, 'YYYY/MM/DD'))
l_log = SET_LOG('Original Date of Hire: ' || TO_CHAR(L_ORIGINAL_HIRE_DATE, 'YYYY/MM/DD'))
l_log = SET_LOG('Latest Rehire Date: ' || TO_CHAR(L_LATEST_REHIRE_DATE, 'YYYY/MM/DD'))

L_CINCO_MESES = ADD_MONTHS(L_PL_END_DATE, -5)
l_log = SET_LOG('Ventana New Hire (5 meses antes de cierre): ' || TO_CHAR(L_CINCO_MESES, 'YYYY/MM/DD'))

IF L_ORIGINAL_HIRE_DATE >= L_CINCO_MESES THEN
(
    l_log = SET_LOG('Candidato a New Hire por ventana. Buscando Assignment ID anterior en PER_HIST_ASG...')

    L_DIA_ANTERIOR = ADD_DAYS(L_HIRE_DATE, -1)
    l_log = SET_LOG('Dia anterior a L_HIRE_DATE: ' || TO_CHAR(L_DIA_ANTERIOR, 'YYYY/MM/DD'))

    /*============================================================================
      RECORRER HISTORIAL: buscar asignacion anterior distinta a la actual cuyo
      rango de fechas cubra el dia previo a L_HIRE_DATE. Se toma la primera
      coincidencia (L_ASG_ID_ANTERIOR = 0 como guarda).
    ============================================================================*/
    L_TOTAL_FILAS = PER_HIST_ASG_EFFECTIVE_START_DATE.LAST(-1)
    l_log = SET_LOG('Total filas historial: ' || TO_CHAR(L_TOTAL_FILAS))

    L_IDX = L_TOTAL_FILAS
    WHILE L_IDX >= 1 LOOP
    (
        L_FILA_INICIO = PER_HIST_ASG_EFFECTIVE_START_DATE[L_IDX]
        L_FILA_FIN    = PER_HIST_ASG_EFFECTIVE_END_DATE[L_IDX]
        L_FILA_ASG_ID = PER_HIST_ASG_ASSIGNMENT_ID[L_IDX]

        IF L_FILA_ASG_ID <> L_CTX_ASG AND
           L_DIA_ANTERIOR >= L_FILA_INICIO AND
           L_DIA_ANTERIOR <= L_FILA_FIN AND
           L_ASG_ID_ANTERIOR = 0 THEN
        (
            L_ASG_ID_ANTERIOR = L_FILA_ASG_ID
            L_IDX = 0
        )
        ELSE
            L_IDX = L_IDX - 1
    )

    l_log = SET_LOG('Assignment ID anterior encontrado: ' || TO_CHAR(L_ASG_ID_ANTERIOR))

    /*============================================================================
      LEER ACTION REASON CODE desde el assignment anterior en L_HIRE_DATE.
      Codigos de exclusion R1: 28, C28, 00, U00, 115.
    ============================================================================*/
    IF L_ASG_ID_ANTERIOR <> 0 THEN
    (
        CHANGE_CONTEXTS(HR_ASSIGNMENT_ID = L_ASG_ID_ANTERIOR, EFFECTIVE_DATE = L_HIRE_DATE)
        (
            L_REASON_CODE = PER_ASG_ACTION_REASON_CODE
        )
        l_log = SET_LOG('Action Reason Code del assignment anterior: ' || L_REASON_CODE)

        IF L_REASON_CODE = '28' OR
           L_REASON_CODE = 'C28' OR
           L_REASON_CODE = '00' OR
           L_REASON_CODE = 'U00' OR
           L_REASON_CODE = '115' THEN
        (
            L_NEW_HIRE = 'N'
            l_log = SET_LOG('Excluido de New Hire: motivo previo en lista R1 (codigo ' || L_REASON_CODE || ')')
        )
        ELSE
        (
            L_NEW_HIRE = 'Y'
            l_log = SET_LOG('Se mantiene como New Hire: motivo previo no esta en lista de exclusion R1')
        )
    )
    ELSE
    (
        L_NEW_HIRE = 'Y'
        l_log = SET_LOG('Se mantiene como New Hire: no se encontro asignacion anterior en historial')
    )
)
ELSE
    l_log = SET_LOG('Fuera de ventana de 5 meses: no aplica New Hire')

L_DEFAULT_VALUE = L_NEW_HIRE

l_log = SET_LOG('*** RESULTADO NEW HIRE R1: ' || L_NEW_HIRE || ' ***')
RETURN L_DEFAULT_VALUE