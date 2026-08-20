/******************************************************************************
* FORMULA NAME      : GB_CMP_INCRM_MERITO_MIN_R1                              *
* FORMULA TYPE      : Compensation Default and Override                       *
* DESCRIPTION       : Obtiene el porcentaje minimo de incremento por merito   *
*                     para paises LAC/LAS y Mexico leyendo desde UDT por      *
*                     pais (comportamiento sin cambios respecto a version 7   *
*                     para todo pais con L_KEY_UDT distinto de 'CO'). Para    *
*                     Colombia (L_KEY_UDT = 'CO') el minimo se hardcodea en   *
*                     formula replicando la logica de comparacion contra      *
*                     Incremento Legal ya validada en GB_CMP_INCRM_MERITO_    *
*                     RANGO_R1 y en GB_CMP_INCRM_MERITO_MAX_R1, tomando el    *
*                     piso inferior de cada rango de texto como valor         *
*                     numerico de minimo.                                     *
*-----------------------------------------------------------------------------*
* CREATED BY        : IT-GLOBAL                                               *
* CREATION DATE     : 07-Abril-2026                                           *
* LAST UPDATE DATE  : 29-Julio-2026                                           *
*-----------------------------------------------------------------------------*
* Change History:                                                             *
* Author          | Date            | Ver | Comments                          *
*-----------------+-----------------+-----+-----------------------------------*
* IT Global       | 15-Abril-2026   |  1  | Version Inicial                   *
* IT Global       | 21-Abril-2026   |  2  | Reestructura dinamica UDT         *
* IT Global       | 14-Mayo-2026    |  3  | Replica logica retrofit promotion *
*                 |                 |     | por recorrido historico de nivel  *
* IT Global       | 27-Mayo-2026    |  4  | Adaptacion R4: key por pais       *
*                 |                 |     | MOR/ESP/PT desde Legal Employer   *
* IT Global       | 28-Mayo-2026    |  5  | Lectura UDT por idioma MOR vs     *
*                 |                 |     | ES_PT; clave con sufijo apertura  *
*                 |                 |     | para Below Expectations y Needs   *
*                 |                 |     | Improvement en MOR                *
* IT Global       | 07-Julio-2026   |  6  | Fix: ajuste de sueldo (x30) y     *
*                 |                 |     | divisor movidos a DESPUES del     *
*                 |                 |     | segundo CHANGE_CONTEXTS, ya que   *
*                 |                 |     | ese bloque volvia a leer          *
*                 |                 |     | CMP_ASSIGNMENT_SALARY_AMOUNT      *
*                 |                 |     | crudo en L_SUELDO, sobreescri-    *
*                 |                 |     | biendo el ajuste y generando      *
*                 |                 |     | apertura negativa incorrecta      *
* IT Global       | 16-Julio-2026   |  7  | Reemplazo de comparacion          *
*                 |                 |     | L_TIPO_CONTRATO = '2' por         *
*                 |                 |     | validacion contra catalogo real   *
*                 |                 |     | de 19 codigos NO PERMANENTE R1    *
*                 |                 |     | (variable L_ES_NO_PERM)           *
* IT Global       | 29-Julio-2026   |  8  | Agregado default inline (4to      *
*                 |                 |     | parametro) en todos los           *
*                 |                 |     | GET_TABLE_VALUE que no lo tenian, *
*                 |                 |     | para evitar error en runtime      *
*                 |                 |     | cuando falta combinacion en UDT.  *
*                 |                 |     | Seccion "RESOLUCION NUMERICA      *
*                 |                 |     | MINIMO" (logica original,         *
*                 |                 |     | intacta) ahora solo aplica cuando *
*                 |                 |     | L_KEY_UDT != 'CO'. Se agrega      *
*                 |                 |     | rama nueva exclusiva para         *
*                 |                 |     | L_KEY_UDT = 'CO': L_CLAVE_CO      *
*                 |                 |     | (switch separado, mismo patron    *
*                 |                 |     | que RANGO_R1 y MAX_R1), lectura   *
*                 |                 |     | de Incremento_Legal, y resolucion *
*                 |                 |     | de L_DEFAULT_MIN hardcodeada      *
*                 |                 |     | tomando el piso de cada rango de  *
*                 |                 |     | texto ya confirmado. Bloque       *
*                 |                 |     | "APLICAR INFLACION MINIMA" sin    *
*                 |                 |     | cambios, aplica igual para ambas  *
*                 |                 |     | ramas.                            *
******************************************************************************/

INPUTS ARE CMP_IV_PLAN_START_DATE (text),
CMP_IV_PLAN_END_DATE (text),
CMP_IVR_ASSIGNMENT_ID(NUMBER_NUMBER),
CMP_IV_PLAN_EXTRACTION_DATE (text)

/*============================================================================
  DEFAULTS
============================================================================*/
DEFAULT_DATA_VALUE FOR CMP_EXTERNAL_WORKER_DATA_RGE_ASG_VALUE1 IS 'N/A'
DEFAULT_DATA_VALUE FOR CMP_EXTERNAL_WORKER_DATA_RGE_ASG_SEQUENCE_NUMBER IS 0
DEFAULT_DATA_VALUE FOR CMP_EXTERNAL_WORKER_DATA_RGE_ASG_ASSIGNMENT_ID IS 0
DEFAULT_DATA_VALUE FOR CMP_EXTERNAL_WORKER_DATA_RGE_ASG_VALUE2 IS 'N/A'
DEFAULT FOR PER_ASG_ATTRIBUTE1 IS 'PERMANENTE'
DEFAULT FOR PER_ASG_ACTION_CODE IS 'N/A'
DEFAULT FOR PER_ASG_EFFECTIVE_START_DATE IS '1900/01/01' (date)
DEFAULT FOR PER_ASG_EFFECTIVE_END_DATE IS '4712/12/31' (date)
DEFAULT FOR PER_ASG_JOB_MANAGER_LEVEL IS 'NA'
DEFAULT FOR PER_ASG_GRADE_ID IS 123
DEFAULT FOR PER_ASG_PERSON_ID IS 0
DEFAULT FOR CMP_ASSIGNMENT_SALARY_AMOUNT IS 0
DEFAULT FOR PER_ASG_ORG_LEGAL_EMPLOYER_NAME IS 'N/LE'
DEFAULT FOR PER_ASG_REL_ORIGINAL_DATE_OF_HIRE IS '1901/01/01' (date)
DEFAULT FOR PER_ASG_ACTION_REASON_CODE IS 'N/A'
DEFAULT_DATA_VALUE FOR PER_HIST_ASG_EFFECTIVE_START_DATE IS '1900/01/01' (date)
DEFAULT_DATA_VALUE FOR PER_HIST_ASG_EFFECTIVE_END_DATE IS '4712/12/31' (date)
DEFAULT_DATA_VALUE FOR PER_HIST_ASG_ASSIGNMENT_ID IS 0


/*============================================================================
  FECHAS BASE
============================================================================*/
HR_EXTRACT_DATE = TO_DATE(CMP_IV_PLAN_EXTRACTION_DATE, 'YYYY/MM/DD')
L_PL_END_DATE   = TO_DATE(CMP_IV_PLAN_END_DATE, 'YYYY/MM/DD')

l_log = SET_LOG('*** INICIO GB_CMP_INCRM_MERITO_MIN_R1 ***')
L_ASG_ID = CMP_IVR_ASSIGNMENT_ID[1]
l_log = SET_LOG('Assignment ID: ' || TO_CHAR(L_ASG_ID))

/*=== INICIO DIAGNOSTICO NUEVO ===*/
L_CTX_ASG = GET_CONTEXT(HR_ASSIGNMENT_ID, -1)
l_log = SET_LOG('Assignment ID segun contexto interno (HR_ASSIGNMENT_ID): ' || TO_CHAR(L_CTX_ASG))
l_log = SET_LOG('Assignment ID segun input CMP_IVR: ' || TO_CHAR(L_ASG_ID))
/*=== FIN DIAGNOSTICO NUEVO ===*/
/*============================================================================
  LEGAL EMPLOYER Y KEY UDT POR PAIS
============================================================================*/
CHANGE_CONTEXTS(EFFECTIVE_DATE = HR_EXTRACT_DATE)
(
    L_LEGAL_EMPLOYER = PER_ASG_ORG_LEGAL_EMPLOYER_NAME
)

l_log = SET_LOG('Legal Employer: ' || L_LEGAL_EMPLOYER)

IF HR_EXTRACT_DATE > L_PL_END_DATE THEN
(
    L_FECHA_CONTEXTO = L_PL_END_DATE
    l_log = SET_LOG('Extraccion posterior al cierre del ciclo, se acota a fin de ciclo')
)
ELSE
(
    L_FECHA_CONTEXTO = HR_EXTRACT_DATE
)

l_log = SET_LOG('Fecha usada en CHANGE_CONTEXTS: ' || TO_CHAR(L_FECHA_CONTEXTO))

IF L_LEGAL_EMPLOYER = 'Bimbo de Colombia, S.A.' THEN
    L_KEY_UDT = 'CO'
ELSE IF L_LEGAL_EMPLOYER = 'Bimbo Ecuador S.A.' THEN
    L_KEY_UDT = 'EC'
ELSE IF L_LEGAL_EMPLOYER = 'Bimbo de Costa Rica, S.A.' THEN
    L_KEY_UDT = 'CR'
ELSE IF L_LEGAL_EMPLOYER = 'Barcel De El Salvador, S.A. de C.V.' OR L_LEGAL_EMPLOYER = 'Bimbo de El Salvador, S.A. de C.V.' THEN
    L_KEY_UDT = 'SV'
ELSE IF L_LEGAL_EMPLOYER = 'Bimbo de Centroamerica, S.A.' OR L_LEGAL_EMPLOYER = 'VeCentral, S.A.' OR L_LEGAL_EMPLOYER = 'Centro de Servicios Compartidos Bimbo, S.A.' THEN
    L_KEY_UDT = 'GT'
ELSE IF L_LEGAL_EMPLOYER = 'Bimbo de Honduras, S.A. de C.V.' OR L_LEGAL_EMPLOYER = 'Compañía Industrial Lido Pozuelo, S.A. de C.V.' THEN
    L_KEY_UDT = 'HN'
ELSE IF L_LEGAL_EMPLOYER = 'Panificadora Bimbo del Uruguay Sociedad Anonima' THEN
    L_KEY_UDT = 'UY'
ELSE IF L_LEGAL_EMPLOYER = 'Bimbo de Panama, S.A.' OR L_LEGAL_EMPLOYER = 'Nutriamericas S.A.' THEN
    L_KEY_UDT = 'PA'
ELSE IF L_LEGAL_EMPLOYER = 'Compañia de Alimentos Fargo, S.A.' THEN
    L_KEY_UDT = 'AR'
ELSE IF L_LEGAL_EMPLOYER = 'Ideal, S.A.' OR L_LEGAL_EMPLOYER = 'Barcel Chile S.A.' THEN
    L_KEY_UDT = 'CL'
ELSE IF L_LEGAL_EMPLOYER = 'Bimbo Paraguay, S.A.' THEN
    L_KEY_UDT = 'PY'
ELSE IF L_LEGAL_EMPLOYER = 'Panificadora Bimbo del Peru, S.A.' THEN
    L_KEY_UDT = 'PE'
ELSE IF L_LEGAL_EMPLOYER = 'Bimbo de Nicaragua, S.A.' THEN
    L_KEY_UDT = 'NI'
ELSE IF L_LEGAL_EMPLOYER = 'Barcel, S.A. de C.V.' OR L_LEGAL_EMPLOYER = 'Bimbonet Servicios, S.A.P.I. de C.V.' OR L_LEGAL_EMPLOYER = 'Bimbo, S.A. de C.V.' OR L_LEGAL_EMPLOYER = 'Corporativo Bimbo, S.A. de C.V.' OR L_LEGAL_EMPLOYER = 'Moldes y Exhibidores, S.A. de C.V.' OR L_LEGAL_EMPLOYER = 'Tradicion en Pastelerías, S.A. de C.V.' THEN
    L_KEY_UDT = 'MEX'
ELSE
    L_KEY_UDT = 'DEFAULT'

l_log = SET_LOG('Key pais UDT: ' || L_KEY_UDT)

/*============================================================================
  PROMEDIO E INFLACION POR PAIS
============================================================================*/
L_PROM      = TO_NUM(GET_TABLE_VALUE('GB_CMP_LAC_LAS_INCREMENTO_MERITO', 'Incremento_Promedio', L_KEY_UDT, '0'))
L_INFLACION = TO_NUM(GET_TABLE_VALUE('GB_CMP_LAC_LAS_INCREMENTO_MERITO', 'Inflacion_Minima', L_KEY_UDT, '0'))
l_log = SET_LOG('Promedio: '  || TO_CHAR(L_PROM))
l_log = SET_LOG('Inflacion: ' || TO_CHAR(L_INFLACION))

/*============================================================================
  UMBRALES E INCREMENTO LEGAL - Unicamente para Colombia (L_KEY_UDT = 'CO')
  Se calculan aqui, antes de construir L_CLAVE_CO, mismo patron ya validado
  en GB_CMP_INCRM_MERITO_RANGO_R1 y GB_CMP_INCRM_MERITO_MAX_R1.
============================================================================*/
IF L_KEY_UDT = 'CO' THEN
(
    IF L_PROM > 10 THEN
        L_MIN_R1_CO = L_PROM - 3
    ELSE IF L_PROM >= 5 AND L_PROM <= 10 THEN
        L_MIN_R1_CO = L_PROM * 0.70
    ELSE
        L_MIN_R1_CO = L_PROM - 1.5

    L_MITAD_PROM_CO = L_PROM / 2

    L_INCR_LEGAL_TXT = GET_TABLE_VALUE('GB_CMP_LAC_LAS_INCREMENTO_MERITO', 'Incremento_Legal', L_KEY_UDT, '0')
    L_INCR_LEGAL     = TO_NUM(L_INCR_LEGAL_TXT)
)
ELSE
(
    L_MIN_R1_CO       = 0
    L_MITAD_PROM_CO   = 0
    L_INCR_LEGAL_TXT  = '0'
    L_INCR_LEGAL      = 0
)

l_log = SET_LOG('Minimo Rango 1 CO: ' || TO_CHAR(L_MIN_R1_CO))
l_log = SET_LOG('Mitad Incremento Promedio CO: ' || TO_CHAR(L_MITAD_PROM_CO))
l_log = SET_LOG('Incremento Legal (numerico): ' || TO_CHAR(L_INCR_LEGAL))
/*============================================================================
  EVALUACION
============================================================================*/
L_EVAL_TXT    = 'N/A'
L_EVAL_MAPPED = 'N/A'
L_IDX         = 0

CHANGE_CONTEXTS(EFFECTIVE_DATE = HR_EXTRACT_DATE, COMPENSATION_RECORD_TYPE = 'CMP_MERITO')
(
    L_IDX = CMP_EXTERNAL_WORKER_DATA_RGE_ASG_SEQUENCE_NUMBER.LAST(-1)
    WHILE L_IDX >= 1 LOOP
    (
        L_EXT_VAL = CMP_EXTERNAL_WORKER_DATA_RGE_ASG_VALUE1[L_IDX]
        IF L_EXT_VAL != 'N/A' THEN
        (
            L_EVAL_MAPPED = GET_TABLE_VALUE('GB_CMP_LAC_LAS_CALIFICAC_MERITO', 'Calificacion_Texto', L_EXT_VAL, 'N/A')
            IF L_EVAL_MAPPED != 'N/A' THEN
            (
                L_EVAL_TXT = L_EVAL_MAPPED
                L_IDX = 0
            )
            ELSE
                L_IDX = L_IDX - 1
        )
        ELSE
            L_IDX = L_IDX - 1
    )
)
l_log = SET_LOG('Evaluacion: ' || L_EVAL_TXT)

/*============================================================================
  LEGAL EMPLOYER, GRADE, SUELDO (primera lectura, solo referencia de log)
============================================================================*/
CHANGE_CONTEXTS(EFFECTIVE_DATE = HR_EXTRACT_DATE)
(
    L_LEGAL_EMPLOYER = PER_ASG_ORG_LEGAL_EMPLOYER_NAME
    L_GRADE          = PER_ASG_GRADE_ID
    L_SUELDO         = CMP_ASSIGNMENT_SALARY_AMOUNT
    L_PER_ID         = PER_ASG_PERSON_ID
)

l_log = SET_LOG('Legal Employer: ' || L_LEGAL_EMPLOYER)
l_log = SET_LOG('Grade ID: '       || TO_CHAR(L_GRADE))
l_log = SET_LOG('Sueldo (crudo, primera lectura): ' || TO_CHAR(L_SUELDO))

/*============================================================================
  DATOS DEL ASSIGNMENT (segunda lectura de L_SUELDO, prevalece esta)
============================================================================*/
CHANGE_CONTEXTS(EFFECTIVE_DATE = HR_EXTRACT_DATE)
(
    L_TIPO_CONTRATO    = PER_ASG_ATTRIBUTE1
    L_ACTION           = PER_ASG_ACTION_CODE
    L_HIRE_DATE        = PER_ASG_EFFECTIVE_START_DATE
    L_GRADE            = PER_ASG_GRADE_ID
    L_SUELDO           = CMP_ASSIGNMENT_SALARY_AMOUNT
    L_PER_ID           = PER_ASG_PERSON_ID
    MGR_LVL            = PER_ASG_JOB_MANAGER_LEVEL
    ASSIGN_START_DATE  = PER_ASG_EFFECTIVE_START_DATE
    ASSIGN_END_DATE    = PER_ASG_EFFECTIVE_END_DATE
)
/*
l_log = SET_LOG('Tipo contrato: ' || L_TIPO_CONTRATO)
l_log = SET_LOG('Action code: '   || L_ACTION)
l_log = SET_LOG('Hire Date: '     || TO_CHAR(L_HIRE_DATE, 'YYYY/MM/DD'))
l_log = SET_LOG('Grade ID: '      || TO_CHAR(L_GRADE))
l_log = SET_LOG('Original Date of Hire: ' || TO_CHAR(PER_ASG_REL_ORIGINAL_DATE_OF_HIRE, 'YYYY/MM/DD'))
l_log = SET_LOG('Sueldo (crudo, segunda lectura): ' || TO_CHAR(L_SUELDO))
l_log = SET_LOG('Manager Level actual: ' || MGR_LVL)
*/
/*============================================================================
  AJUSTE DE SUELDO Y DIVISOR
  Se aplica AQUI, despues del ultimo CHANGE_CONTEXTS que lee L_SUELDO, para
  que ningun bloque posterior sobreescriba el ajuste con el valor crudo.
============================================================================*/
IF L_KEY_UDT = 'CO' OR L_KEY_UDT = 'EC' OR L_KEY_UDT = 'AR' OR L_KEY_UDT = 'PE' OR L_KEY_UDT = 'PY' THEN
(
    L_SUELDO  = L_SUELDO
)
ELSE
(
    L_SUELDO  = L_SUELDO * 30.4168
)

L_DIVISOR = 30
/*

l_log = SET_LOG('Sueldo ajustado (final): ' || TO_CHAR(L_SUELDO))
l_log = SET_LOG('Divisor periodicidad: '     || TO_CHAR(L_DIVISOR))
*/
/*============================================================================
  CALCULO APERTURA
============================================================================*/
L_PARAM_PER = '|=PERSON_ID=' || TO_CHAR(L_PER_ID) || '|P_ASSIGNMENT_ID=' || TO_CHAR(L_CTX_ASG) || '|P_EFFECTIVE_DATE=' || TO_CHAR(L_FECHA_CONTEXTO, 'YYYY/MM/DD')
L_RATE_ID = TO_NUM(GET_VALUE_SET('GB_CMP_ASG_RATE_ID', L_PARAM_PER))
l_log = SET_LOG('Rate ID: ' || TO_CHAR(L_RATE_ID))

IF L_RATE_ID > 0 THEN
(
    L_PARAM_MIN = '|=P_ASSIGNMENT_RATE=' || TO_CHAR(L_RATE_ID) || '|P_ASSIGNMENT_GRADE=' || TO_CHAR(L_GRADE) || '|P_EFFECTIVE_DATE=' || TO_CHAR(L_FECHA_CONTEXTO, 'YYYY/MM/DD')
    L_PARAM_MAX = '|=P_ASSIGNMENT_GRADE=' || TO_CHAR(L_GRADE)  || '|P_ASSIGNMENT_RATE='  || TO_CHAR(L_RATE_ID) || '|P_EFFECTIVE_DATE=' || TO_CHAR(L_FECHA_CONTEXTO, 'YYYY/MM/DD')
    L_MIN = TO_NUM(GET_VALUE_SET('GB_CMP_RATE_ID_VALUE_MIN', L_PARAM_MIN))
    L_MAX = TO_NUM(GET_VALUE_SET('GB_CMP_RATE_ID_VALUE_MAX', L_PARAM_MAX))
)
ELSE
(
    L_PARAM_GRADE = '|=P_ASSIGNMENT_GRADE=' || TO_CHAR(L_GRADE) || '|P_EFFECTIVE_DATE=' || TO_CHAR(L_FECHA_CONTEXTO, 'YYYY/MM/DD')
    L_MIN = TO_NUM(GET_VALUE_SET('GB_CMP_RATE_VALUE_MIN', L_PARAM_GRADE))
    L_MAX = TO_NUM(GET_VALUE_SET('GB_CMP_RATE_VALUE_MAX', L_PARAM_GRADE))
)

l_log = SET_LOG('Min plan: ' || TO_CHAR(L_MIN))
l_log = SET_LOG('Max plan: ' || TO_CHAR(L_MAX))

IF L_MAX = L_MIN THEN
    L_APERTURA = 0
ELSE
(
    L_VALOR_PUNTO = (L_MAX - L_MIN) / L_DIVISOR
    L_APERTURA    = ((L_SUELDO - L_MIN) / L_VALOR_PUNTO) + 70
)
l_log = SET_LOG('Apertura calculada: ' || TO_CHAR(L_APERTURA))
l_log = SET_LOG('Valor del punto : '  || TO_CHAR(L_VALOR_PUNTO))

/*============================================================================
  DETECCION DE PROMOCION POR RETROFIT
============================================================================*/
PROMOTION_START_DATE = ADD_MONTHS(L_PL_END_DATE, -5)
PROMOTION_END_DATE   = HR_EXTRACT_DATE
/*
l_log = SET_LOG('Promotion Start Date: ' || TO_CHAR(PROMOTION_START_DATE, 'YYYY/MM/DD'))
l_log = SET_LOG('Promotion End Date: '   || TO_CHAR(PROMOTION_END_DATE,   'YYYY/MM/DD'))
*/
LEVEL1       = 'NA'
PRIOR_LEVEL  = 'NA'
LEVEL_CHANGE = 'N'
PRO          = 'N'
L_COUNT      = 0

IF ASSIGN_START_DATE >= PROMOTION_START_DATE AND ASSIGN_START_DATE <= PROMOTION_END_DATE THEN
(
    WHILE L_COUNT <= 10 LOOP
    (
        L_COUNT = L_COUNT + 1
        PRIOR_ASSIGN_START_DATE = ADD_DAYS(ASSIGN_START_DATE, -1)

        IF ASSIGN_END_DATE > PROMOTION_START_DATE THEN
        (
            CHANGE_CONTEXTS(EFFECTIVE_DATE = PRIOR_ASSIGN_START_DATE)
            (
                PRIOR_ASSIGN_START_DATE = PER_ASG_EFFECTIVE_START_DATE
                PRIOR_ASSIGN_END_DATE   = PER_ASG_EFFECTIVE_END_DATE
                PRIOR_LEVEL             = PER_ASG_JOB_MANAGER_LEVEL

                IF PRIOR_LEVEL != 'NA' AND PRIOR_LEVEL = MGR_LVL THEN
                (
                    ASSIGN_START_DATE = PRIOR_ASSIGN_START_DATE
                )
                ELSE
                (
                    IF PRIOR_ASSIGN_END_DATE < PROMOTION_START_DATE THEN
                    (
                        ASSIGN_START_DATE = PRIOR_ASSIGN_START_DATE
                    )
                    ELSE
                    (
                        LEVEL1  = PRIOR_LEVEL
                        L_COUNT = 11
                    )
                )
            )
        )
    )
)

IF LEVEL1 != 'NA' AND MGR_LVL != 'NA' THEN
(
    IF TO_NUM(MGR_LVL) > TO_NUM(LEVEL1) THEN
        LEVEL_CHANGE = 'Y'
)

IF LEVEL_CHANGE = 'Y' THEN
    PRO = 'PRO'
/*
l_log = SET_LOG('Level previo (LEVEL1): ' || LEVEL1)
l_log = SET_LOG('Level change: '          || LEVEL_CHANGE)
l_log = SET_LOG('PRO flag: '              || PRO)
*/



/*============================================================================
  DETECCION DE TRANSFERENCIA INTERCOMPANIA
  Misma logica validada en GB_CMP_NEW_HIRE_RETROFIT v11.
============================================================================*/
L_ES_INTERCOMPANIA = 'N'

IF PER_ASG_REL_ORIGINAL_DATE_OF_HIRE >= PROMOTION_START_DATE THEN
(
    L_DIA_ANT_HIRE = ADD_DAYS(L_HIRE_DATE, -1)
    L_ASG_ANT = 0
    L_TOTAL_HIST = PER_HIST_ASG_EFFECTIVE_START_DATE.LAST(-1)
    L_H = L_TOTAL_HIST
    WHILE L_H >= 1 LOOP
    (
        L_H_INICIO = PER_HIST_ASG_EFFECTIVE_START_DATE[L_H]
        L_H_FIN = PER_HIST_ASG_EFFECTIVE_END_DATE[L_H]
        L_H_ASG = PER_HIST_ASG_ASSIGNMENT_ID[L_H]

        IF L_H_ASG <> L_CTX_ASG AND L_DIA_ANT_HIRE >= L_H_INICIO AND L_DIA_ANT_HIRE <= L_H_FIN AND L_ASG_ANT = 0 THEN
        (
            L_ASG_ANT = L_H_ASG
            L_H = 0
        )
        ELSE
            L_H = L_H - 1
    )

    IF L_ASG_ANT <> 0 THEN
    (
        L_RC = 'N/A'
        CHANGE_CONTEXTS(HR_ASSIGNMENT_ID = L_ASG_ANT, EFFECTIVE_DATE = L_HIRE_DATE)
        (
            L_RC = PER_ASG_ACTION_REASON_CODE
        )
        l_log = SET_LOG('Reason code assignment anterior: ' || L_RC)

        IF L_RC = '28'
        OR L_RC = '098'
        OR L_RC = 'ES098'
        OR L_RC = 'ES98'
        OR L_RC = 'BUK_30'
        OR L_RC = 'INTERNREC'
        OR L_RC = 'REORG'
        OR L_RC = 'WORKERREQ'
        THEN
            L_ES_INTERCOMPANIA = 'Y'
    )
)

l_log = SET_LOG('Es intercompania: ' || L_ES_INTERCOMPANIA)


/*============================================================================
  VALIDACION DE CONTRATO NO PERMANENTE (catalogo real R1)
============================================================================*/
IF L_TIPO_CONTRATO = 'AR25' OR
   L_TIPO_CONTRATO = 'FA12' OR
   L_TIPO_CONTRATO = 'FA14' OR
   L_TIPO_CONTRATO = 'FA22' OR
   L_TIPO_CONTRATO = 'CL22' OR
   L_TIPO_CONTRATO = 'CR2'  OR
   L_TIPO_CONTRATO = '00020' OR
   L_TIPO_CONTRATO = '00022' OR
   L_TIPO_CONTRATO = '00023' OR
   L_TIPO_CONTRATO = 'MEX1' OR
   L_TIPO_CONTRATO = 'MEX3' OR
   L_TIPO_CONTRATO = 'MEX5' OR
   L_TIPO_CONTRATO = 'PY1'  OR
   L_TIPO_CONTRATO = 'PE03' OR
   L_TIPO_CONTRATO = 'PE05' OR
   L_TIPO_CONTRATO = 'UY02' OR
   L_TIPO_CONTRATO = 'UY04' OR
   L_TIPO_CONTRATO = 'UY05' OR
   L_TIPO_CONTRATO = 'UY06' THEN
    L_ES_NO_PERM = 'Y'
ELSE
    L_ES_NO_PERM = 'N'

l_log = SET_LOG('Es No Permanente: ' || L_ES_NO_PERM)

/*============================================================================
  CONDICION
============================================================================*/
L_CINCO_MESES = ADD_MONTHS(L_PL_END_DATE, -5)

IF PRO = 'PRO' THEN
    L_CONDICION = 'Promotion'
ELSE IF L_ES_NO_PERM = 'Y' THEN
    L_CONDICION = 'NonPerm'
ELSE IF PER_ASG_REL_ORIGINAL_DATE_OF_HIRE >= L_CINCO_MESES
AND L_ES_INTERCOMPANIA = 'N'
 THEN
    L_CONDICION = 'NewHire'
ELSE
    L_CONDICION = 'None'

l_log = SET_LOG('Condicion: ' || L_CONDICION)

/*============================================================================
  CONSTRUCCION DE CLAVE UDT (SIN CAMBIOS) - usada por GET_TABLE_VALUE sobre
  GB_CMP_LAS_LAC_RANGOS_MERITO / GB_CMP_CO_RANGOS_MERITO para todo pais con
  L_KEY_UDT != 'CO'
============================================================================*/
IF L_CONDICION = 'Promotion' AND (L_EVAL_TXT = 'Sobresaliente' OR L_EVAL_TXT = 'Supera' OR L_EVAL_TXT = 'Cumple con lo esperado') THEN
    L_CLAVE = 'Promotion'
ELSE IF L_CONDICION = 'NonPerm' THEN
    L_CLAVE = 'NonPerm'
ELSE IF L_CONDICION = 'NewHire' THEN
    L_CLAVE = 'NewHire'
ELSE IF L_EVAL_TXT = 'N/A' THEN
    L_CLAVE = 'SinEval'
ELSE IF L_EVAL_TXT = 'Exit' THEN
    L_CLAVE = 'Exit'
ELSE IF L_EVAL_TXT = 'Salida' THEN
    L_CLAVE = 'Salida'
ELSE IF L_APERTURA <= 100 THEN
    L_CLAVE = L_EVAL_TXT || '_LT100'
ELSE
    L_CLAVE = L_EVAL_TXT || '_GE100'

l_log = SET_LOG('Clave UDT: ' || L_CLAVE)

/*============================================================================
  CLAVE COLOMBIA - calcula la comparacion contra Incremento_Legal y
  construye la key con sufijo. Solo se calcula si L_KEY_UDT = 'CO'. Usa
  L_MIN_R1_CO / L_MITAD_PROM_CO / L_INCR_LEGAL ya calculados arriba, en el
  bloque UMBRALES E INCREMENTO LEGAL. Mismo patron ya validado en
  GB_CMP_INCRM_MERITO_RANGO_R1 y GB_CMP_INCRM_MERITO_MAX_R1.
============================================================================*/
IF L_KEY_UDT = 'CO' THEN
(
    IF L_CONDICION = 'Promotion' AND L_EVAL_TXT = 'Sobresaliente' THEN
        L_CLAVE_CO = 'Sobresaliente_Prom'
    ELSE IF L_CONDICION = 'NonPerm' THEN
    (
        IF L_INCR_LEGAL > L_MIN_R1_CO THEN
            L_CLAVE_CO = 'NonPerm_GE_MINR1'
        ELSE
            L_CLAVE_CO = 'NonPerm_LT_MINR1'
    )
    ELSE IF L_CONDICION = 'NewHire' THEN
    (
        IF L_INCR_LEGAL > L_MIN_R1_CO THEN
            L_CLAVE_CO = 'NewHire_GE_MINR1'
        ELSE
            L_CLAVE_CO = 'NewHire_LT_MINR1'
    )
    ELSE IF L_EVAL_TXT = 'N/A' THEN
    (
        IF L_INCR_LEGAL > L_MIN_R1_CO THEN
            L_CLAVE_CO = 'SinEval_GE_MINR1'
        ELSE
            L_CLAVE_CO = 'SinEval_LT_MINR1'
    )
    ELSE IF L_EVAL_TXT = 'Exit' OR L_EVAL_TXT = 'Salida' THEN
        L_CLAVE_CO = 'Salida'
    ELSE IF L_EVAL_TXT = 'Necesita mejora' OR L_EVAL_TXT = 'Por debajo de lo esperado' THEN
    (
        IF L_INCR_LEGAL > L_MITAD_PROM_CO THEN
            L_CLAVE_CO = L_EVAL_TXT || '_GE_MITADPROM'
        ELSE
            L_CLAVE_CO = L_EVAL_TXT || '_LT_MITADPROM'
    )
    ELSE IF L_EVAL_TXT = 'Sobresaliente' AND L_APERTURA < 100 THEN
        L_CLAVE_CO = 'Sobresaliente_LT100'
    ELSE IF L_EVAL_TXT = 'Sobresaliente' AND L_APERTURA >= 100 THEN
    (
        IF L_INCR_LEGAL > L_MIN_R1_CO THEN
            L_CLAVE_CO = 'Sobresaliente_GE100_GE_MINR1'
        ELSE
            L_CLAVE_CO = 'Sobresaliente_GE100_LT_MINR1'
    )
    ELSE IF L_EVAL_TXT = 'Cumple con lo esperado' AND L_APERTURA < 100 THEN
    (
        IF L_INCR_LEGAL > L_MIN_R1_CO THEN
            L_CLAVE_CO = 'Cumple con lo esperado_LT100_GE_MINR1'
        ELSE
            L_CLAVE_CO = 'Cumple con lo esperado_LT100_LT_MINR1'
    )
    ELSE IF L_EVAL_TXT = 'Cumple con lo esperado' AND L_APERTURA >= 100 THEN
    (
        IF L_INCR_LEGAL > L_MIN_R1_CO THEN
            L_CLAVE_CO = 'Cumple con lo esperado_GE100_GE_MINR1'
        ELSE
            L_CLAVE_CO = 'Cumple con lo esperado_GE100_LT_MINR1'
    )
    ELSE IF L_EVAL_TXT = 'Supera' AND L_APERTURA < 100 THEN
        L_CLAVE_CO = 'Supera_LT100'
    ELSE IF L_EVAL_TXT = 'Supera' AND L_APERTURA >= 100 THEN
        L_CLAVE_CO = 'Supera_GE100'
    ELSE
        L_CLAVE_CO = 'SinClasificar'
)
ELSE
    L_CLAVE_CO = 'N/A'

l_log = SET_LOG('Clave switch CO: ' || L_CLAVE_CO)

/*============================================================================
  LECTURA UDT POR IDIOMA (SIN CAMBIOS)
============================================================================*/

IF L_KEY_UDT = 'CO' THEN
(
    L_RANGO_MIN  = GET_TABLE_VALUE('GB_CMP_CO_RANGOS_MERITO', 'Rango_Minimo', L_CLAVE_CO, 'NO')
    L_APLICA_INF = GET_TABLE_VALUE('GB_CMP_CO_RANGOS_MERITO', 'Aplica_Inflacion', L_CLAVE_CO, 'N')
)
ELSE
(
    L_RANGO_MIN  = GET_TABLE_VALUE('GB_CMP_LAS_LAC_RANGOS_MERITO', 'Rango_Minimo', L_CLAVE, 'NO')
    L_APLICA_INF = GET_TABLE_VALUE('GB_CMP_LAS_LAC_RANGOS_MERITO', 'Aplica_Inflacion', L_CLAVE, 'N')
)

/*============================================================================
  CALCULO VALORES NUMERICOS POR RANGO (SIN CAMBIOS)
  Nota: en este archivo L_VAL_R1..R4 representan el PISO de cada tier
  (equivalen a los valores _MIN de GB_CMP_INCRM_MERITO_MAX_R1). Se reutilizan
  tal cual para el piso de cada condicion de Colombia.
============================================================================*/
IF L_PROM > 10 THEN
(
    L_VAL_R1 = L_PROM - 3
    L_VAL_R2 = L_PROM - 1.5
    L_VAL_R3 = L_PROM
    L_VAL_R4 = L_PROM + 1.5
    L_VAL_R4_MAX = L_PROM + 3
)
ELSE IF L_PROM >= 5 AND L_PROM <= 10 THEN
(
    L_VAL_R1 = L_PROM * 0.70
    L_VAL_R2 = L_PROM * 0.85
    L_VAL_R3 = L_PROM
    L_VAL_R4 = L_PROM * 1.15
    L_VAL_R4_MAX = L_PROM * 1.30
)
ELSE
(
    L_VAL_R1 = L_PROM - 1.5
    L_VAL_R2 = L_PROM - 0.75
    L_VAL_R3 = L_PROM
    L_VAL_R4 = L_PROM + 0.75
    L_VAL_R4_MAX = L_PROM + 1.5
)
l_log = SET_LOG('Val R1: ' || TO_CHAR(L_VAL_R1))
l_log = SET_LOG('Val R2: ' || TO_CHAR(L_VAL_R2))
l_log = SET_LOG('Val R3: ' || TO_CHAR(L_VAL_R3))
l_log = SET_LOG('Val R4: ' || TO_CHAR(L_VAL_R4))

/*============================================================================
  RESOLUCION NUMERICA MINIMO
  Unificada para todos los paises, incluida Colombia. L_RANGO_MIN ya viene
  resuelto por pais desde la UDT correspondiente (L_CLAVE_CO para CO,
  L_CLAVE para el resto), ambas entregan el mismo tipo de codigo
  (R1, R1_MIN, R2, R3, R4, PROM, MITAD, NO).
============================================================================*/
IF L_RANGO_MIN = 'NO' THEN
    L_DEFAULT_MIN = 0
ELSE IF L_RANGO_MIN = 'R0_MIN' THEN
    L_DEFAULT_MIN = 0
ELSE IF L_RANGO_MIN = 'R0_MAX' THEN
    L_DEFAULT_MIN = L_VAL_R1
ELSE IF L_RANGO_MIN = 'R1_MIN' OR L_RANGO_MIN = 'R1' THEN
    L_DEFAULT_MIN = L_VAL_R1
ELSE IF L_RANGO_MIN = 'R1_MAX' THEN
    L_DEFAULT_MIN = L_VAL_R2
ELSE IF L_RANGO_MIN = 'R2_MIN' OR L_RANGO_MIN = 'R2' THEN
    L_DEFAULT_MIN = L_VAL_R2
ELSE IF L_RANGO_MIN = 'R2_MAX' THEN
    L_DEFAULT_MIN = L_VAL_R3
ELSE IF L_RANGO_MIN = 'R3_MIN' OR L_RANGO_MIN = 'R3' THEN
    L_DEFAULT_MIN = L_VAL_R3
ELSE IF L_RANGO_MIN = 'R3_MAX' THEN
    L_DEFAULT_MIN = L_VAL_R4
ELSE IF L_RANGO_MIN = 'R4_MIN' OR L_RANGO_MIN = 'R4' THEN
    L_DEFAULT_MIN = L_VAL_R4
ELSE IF L_RANGO_MIN = 'R4_MAX' THEN
    L_DEFAULT_MIN = L_VAL_R4_MAX
ELSE IF L_RANGO_MIN = 'PROM' THEN
    L_DEFAULT_MIN = L_PROM
ELSE IF L_RANGO_MIN = 'HALF_PROM' THEN
    L_DEFAULT_MIN = L_PROM / 2
ELSE IF L_RANGO_MIN = 'MITAD' THEN
    L_DEFAULT_MIN = L_PROM / 2
ELSE IF L_RANGO_MIN = 'INC_LG' THEN
    L_DEFAULT_MIN = L_INCR_LEGAL
ELSE
    L_DEFAULT_MIN = 0
/*============================================================================
  APLICAR INFLACION MINIMA (SIN CAMBIOS)
============================================================================*/
IF L_APLICA_INF = 'S' AND L_DEFAULT_MIN < L_INFLACION THEN
    L_DEFAULT_MIN = L_INFLACION

l_log = SET_LOG('*** RESULTADO MIN: ' || TO_CHAR(L_DEFAULT_MIN) || ' ***')
RETURN L_DEFAULT_MIN