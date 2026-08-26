/**********************************************************************
FORMULA NAME      : GB_CMP_NEW_HIRE_RETROFIT
CREATED_BY        : IT-GLOBAL
CREATION_DATE     : (segun version original)
LAST_UPDATE_DATE  : 25 de Agosto del 2026
FORMULA TYPE      : Compensation Default and Override
DESCRIPTION       : Identifica si el colaborador es New Hire para R1, usando
                    ventana de 5 meses antes del cierre del plan. Excluye
                    transferencias e intercompany leyendo el ACTION_REASON_CODE
                    de la asignacion anterior terminada. Si el motivo previo
                    esta en la lista de exclusion, no se considera New Hire.
                    Codigos de exclusion R1: 28, C28, 00, U00, 115.
                    REHIRE_WK es codigo receptor: no se lee, se excluye por
                    ausencia de asignacion anterior valida.
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

L_DEFAULT_VALUE = 'N'
L_NEW_HIRE = 'N'
L_ES_EXCLUIDO = 'N'
L_ACTION_REASON_PREV = 'N/A'
L_ASG_ID_ANTERIOR = 0

HR_EXTRACT_DATE = TO_DATE(CMP_IV_PLAN_EXTRACTION_DATE, 'YYYY/MM/DD')
L_PL_START_DATE = TO_DATE(CMP_IV_PLAN_START_DATE, 'YYYY/MM/DD')
L_PL_END_DATE   = TO_DATE(CMP_IV_PLAN_END_DATE, 'YYYY/MM/DD')

l_log = SET_LOG('*** INICIO GB_CMP_NEW_HIRE_RETROFIT R1 ***')
l_log = SET_LOG('Fecha extraccion: ' || TO_CHAR(HR_EXTRACT_DATE))
l_log = SET_LOG('Fecha inicio plan: ' || TO_CHAR(L_PL_START_DATE))
l_log = SET_LOG('Fecha fin plan: ' || TO_CHAR(L_PL_END_DATE))

/*=== DIAGNOSTICO ASSIGNMENT ACTUAL ===*/
L_CTX_ASG = GET_CONTEXT(HR_ASSIGNMENT_ID, -1)
l_log = SET_LOG('Assignment ID segun contexto interno (HR_ASSIGNMENT_ID): ' || TO_CHAR(L_CTX_ASG))

L_HIRE_DATE = PER_ASG_EFFECTIVE_START_DATE
L_ORIGINAL_HIRE_DATE = PER_ASG_REL_ORIGINAL_DATE_OF_HIRE
L_LATEST_REHIRE_DATE = PER_PER_LATEST_REHIRE_DATE

l_log = SET_LOG('Assignment Start Date: ' || TO_CHAR(L_HIRE_DATE, 'YYYY/MM/DD'))
l_log = SET_LOG('Original Date of Hire: ' || TO_CHAR(L_ORIGINAL_HIRE_DATE, 'YYYY/MM/DD'))
l_log = SET_LOG('Last Rehire Date: ' || TO_CHAR(L_LATEST_REHIRE_DATE, 'YYYY/MM/DD'))

/*============================================================================
  VENTANA DE 5 MESES ANTES DEL CIERRE DEL PLAN
============================================================================*/
L_CINCO_MESES = ADD_MONTHS(L_PL_END_DATE, -5)
l_log = SET_LOG('Ventana New Hire (5 meses antes de cierre): ' || TO_CHAR(L_CINCO_MESES, 'YYYY/MM/DD'))

/*============================================================================
  DETECCION DE ASIGNACION ANTERIOR (transferencia / intercompany)
  Resuelve el HR_ASSIGNMENT_ID de la asignacion previa terminada del mismo
  worker via Value Set. Si existe, se lee su ACTION_REASON_CODE en la fecha
  de contratacion actual (L_HIRE_DATE) y se compara contra la lista R1.
============================================================================*/
L_ASG_ID_ANTERIOR = TO_NUM(GET_VALUE_SET('GB_CMP_VS_ASG_ANTERIOR', '|=PERSON_ID_CONTEXT|'))
l_log = SET_LOG('Assignment ID anterior resuelto: ' || TO_CHAR(L_ASG_ID_ANTERIOR))

IF L_ASG_ID_ANTERIOR > 0 THEN
(
    CHANGE_CONTEXTS(HR_ASSIGNMENT_ID = L_ASG_ID_ANTERIOR, EFFECTIVE_DATE = L_HIRE_DATE)
    (
        L_ACTION_REASON_PREV = PER_ASG_ACTION_REASON_CODE
    )
    l_log = SET_LOG('Action Reason Code asignacion anterior: ' || L_ACTION_REASON_PREV)

    IF L_ACTION_REASON_PREV = '28' OR
       L_ACTION_REASON_PREV = 'C28' OR
       L_ACTION_REASON_PREV = '00' OR
       L_ACTION_REASON_PREV = 'U00' OR
       L_ACTION_REASON_PREV = '115' THEN
    (
        L_ES_EXCLUIDO = 'Y'
        l_log = SET_LOG('Motivo previo en lista de exclusion R1: se descarta como New Hire')
    )
    ELSE
        l_log = SET_LOG('Motivo previo NO esta en lista de exclusion R1')
)
ELSE
    l_log = SET_LOG('Este usuario no contiene asignaciones anteriores')

/*============================================================================
  EVALUACION FINAL NEW HIRE
============================================================================*/
IF L_ES_EXCLUIDO = 'N' AND L_ORIGINAL_HIRE_DATE >= L_CINCO_MESES THEN
    L_NEW_HIRE = 'Y'
ELSE
    L_NEW_HIRE = 'N'

L_DEFAULT_VALUE = L_NEW_HIRE

l_log = SET_LOG('*** RESULTADO NEW HIRE R1: ' || L_NEW_HIRE || ' ***')
RETURN L_DEFAULT_VALUE