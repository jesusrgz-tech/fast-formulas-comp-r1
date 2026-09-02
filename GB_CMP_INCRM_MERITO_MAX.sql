/******************************************************************************
* FORMULA NAME      : GB_CMP_INCRM_MERITO_MAX                                 *
* FORMULA TYPE      : Compensation Default and Override                       *
* DESCRIPTION       : Obtiene el porcentaje maximo de incremento por merito   *
*                     de forma dinamica desde UDT GB_CMP_RANGOS_MERITO.       *
*                     Incremento Legal BR: mismo patron que Colombia (R1) -   *
*                     todas las condiciones excepto Promotion y Salida        *
*                     comparan Incremento_Legal contra Minimo Rango 1 o       *
*                     Mitad de Incremento Promedio y sufijan L_CLAVE con el   *
*                     resultado. Se elimino el mecanismo anterior de bandera  *
*                     Aplica_Inflacion + sustitucion al final.                *
*-----------------------------------------------------------------------------*
* CREATED BY        : IT-GLOBAL                                               *
* CREATION DATE     : 07-Abril-2026                                           *
* LAST UPDATE DATE  : 01-Septiembre-2026                                      *
*-----------------------------------------------------------------------------*
* Change History:                                                             *
* Author          | Date            | Ver | Comments                          *
*-----------------+-----------------+-----+-----------------------------------*
* IT Global       | 15-Abril-2026   |  1  | Version Inicial                   *
* IT Global       | 21-Abril-2026   |  2  | Reestructura dinamica UDT         *
* IT Global       | 01-Sept-2026    |  3  | Incremento Legal BR: reemplazo de *
*                 |                 |     | bandera Aplica_Inflacion por      *
*                 |                 |     | clave sufijada (patron Colombia). *
*                 |                 |     | Agregada resolucion INC_LG.       *
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

/*============================================================================
  FECHAS BASE
============================================================================*/
HR_EXTRACT_DATE = TO_DATE(CMP_IV_PLAN_EXTRACTION_DATE, 'YYYY/MM/DD')
L_PL_END_DATE   = TO_DATE(CMP_IV_PLAN_END_DATE, 'YYYY/MM/DD')

l_log = SET_LOG('*** INICIO GB_CMP_INCRM_MERITO_MAX ***')
L_ASG_ID = CMP_IVR_ASSIGNMENT_ID[1]
l_log = SET_LOG('Assignment ID: ' || TO_CHAR(L_ASG_ID))

/*============================================================================
  PROMEDIO E INCREMENTO LEGAL BR
  Se obtiene el incremento promedio y el incremento legal desde la UDT
  GB_CMP_BR_INCREMENTO_MERITO para la clave BR. Se calculan tambien los
  umbrales de comparacion Minimo Rango 1 y Mitad de Incremento Promedio,
  mismo patron ya validado en GB_CMP_INCRM_MERITO_RANGO_R1 (Colombia).
============================================================================*/
L_PROM       = TO_NUMBER(GET_TABLE_VALUE('GB_CMP_BR_INCREMENTO_MERITO', 'Incremento_Promedio', 'BR'))
L_INCR_LEGAL = TO_NUMBER(GET_TABLE_VALUE('GB_CMP_BR_INCREMENTO_MERITO', 'Incremento_Legal', 'BR'))
l_log = SET_LOG('Promedio BR: '        || TO_CHAR(L_PROM))
l_log = SET_LOG('Incremento Legal BR: ' || TO_CHAR(L_INCR_LEGAL))

IF L_PROM > 10 THEN
    L_MIN_R1 = L_PROM - 3
ELSE IF L_PROM >= 5 AND L_PROM <= 10 THEN
    L_MIN_R1 = L_PROM * 0.70
ELSE
    L_MIN_R1 = L_PROM - 1.5

L_MITAD_PROM = L_PROM / 2

l_log = SET_LOG('Minimo Rango 1 BR: ' || TO_CHAR(L_MIN_R1))
l_log = SET_LOG('Mitad Incremento Promedio BR: ' || TO_CHAR(L_MITAD_PROM))

/*============================================================================
  EVALUACION
  Se recorre el historial de datos externos con tipo CMP_MERITO
  y se mapea el valor numerico a texto usando GB_CMP_CALIFICAC_MERITO
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
            L_EVAL_MAPPED = GET_TABLE_VALUE('GB_CMP_CALIFICAC_MERITO', 'Calificacion_Texto', L_EXT_VAL)
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
  DATOS DEL ASSIGNMENT
  Se obtienen tipo de contrato, action code, fecha de contratacion,
  grado, sueldo y person ID con contexto a la fecha de extraccion
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

l_log = SET_LOG('Tipo contrato: ' || L_TIPO_CONTRATO)
l_log = SET_LOG('Action code: '   || L_ACTION)
l_log = SET_LOG('Hire Date: '     || TO_CHAR(L_HIRE_DATE, 'YYYY/MM/DD'))
l_log = SET_LOG('Grade ID: '      || TO_CHAR(L_GRADE))
l_log = SET_LOG('Sueldo: '        || TO_CHAR(L_SUELDO))
l_log = SET_LOG('Manager Level Actual : ' || MGR_LVL)

/*============================================================================
  CALCULO APERTURA
  Se obtienen min y max del plan salarial via Value Sets y se calcula
  la apertura del empleado respecto a su banda salarial
============================================================================*/
L_PARAM_PER = '|=PERSON_ID=' || TO_CHAR(L_PER_ID)
L_RATE_ID   = TO_NUM(GET_VALUE_SET('GB_CMP_ASG_RATE_ID', L_PARAM_PER))
l_log = SET_LOG('Rate ID: ' || TO_CHAR(L_RATE_ID))

IF L_RATE_ID > 0 THEN
(
    L_PARAM_MIN = '|=P_ASSIGNMENT_RATE=' || TO_CHAR(L_RATE_ID) || '|P_ASSIGNMENT_GRADE=' || TO_CHAR(L_GRADE)
    L_PARAM_MAX = '|=P_ASSIGNMENT_GRADE=' || TO_CHAR(L_GRADE)  || '|P_ASSIGNMENT_RATE='  || TO_CHAR(L_RATE_ID)
    L_MIN = TO_NUM(GET_VALUE_SET('GB_CMP_RATE_ID_VALUE_MIN', L_PARAM_MIN))
    L_MAX = TO_NUM(GET_VALUE_SET('GB_CMP_RATE_ID_VALUE_MAX', L_PARAM_MAX))
)
ELSE
(
    L_PARAM_GRADE = '|=P_ASSIGNMENT_GRADE=' || TO_CHAR(L_GRADE)
    L_MIN = TO_NUM(GET_VALUE_SET('GB_CMP_RATE_VALUE_MIN', L_PARAM_GRADE))
    L_MAX = TO_NUM(GET_VALUE_SET('GB_CMP_RATE_VALUE_MAX', L_PARAM_GRADE))
)

l_log = SET_LOG('Min plan: ' || TO_CHAR(L_MIN))
l_log = SET_LOG('Max plan: ' || TO_CHAR(L_MAX))

IF L_MAX = L_MIN THEN
    L_APERTURA = 0
ELSE
(
    L_VALOR_PUNTO = (L_MAX - L_MIN) / 30
    L_APERTURA    = ((L_SUELDO - L_MIN) / L_VALOR_PUNTO) + 70
)
l_log = SET_LOG('Apertura calculada: ' || TO_CHAR(L_APERTURA))

/*============================================================================
  DETECCION DE PROMOCION POR RETROFIT
  Se replica la logica de GB_CMP_PROMOTION_RETROFIT_MERITO:
  ventana de 5 meses previa a la fecha fin del plan, recorrido del
  historial de assignments comparando manager level actual vs previo.
  Solo se marca PRO cuando hay incremento real de nivel ascendente
  dentro de la ventana.
============================================================================*/
PROMOTION_START_DATE = ADD_MONTHS(L_PL_END_DATE, -5)
PROMOTION_END_DATE   = HR_EXTRACT_DATE

l_log = SET_LOG('Promotion Start Date: ' || TO_CHAR(PROMOTION_START_DATE, 'YYYY/MM/DD'))
l_log = SET_LOG('Promotion End Date: '   || TO_CHAR(PROMOTION_END_DATE,   'YYYY/MM/DD'))

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
    IF TO_NUMBER(MGR_LVL) > TO_NUMBER(LEVEL1) THEN
        LEVEL_CHANGE = 'Y'
)

IF LEVEL_CHANGE = 'Y' THEN
    PRO = 'PRO'

l_log = SET_LOG('Level previo (LEVEL1): ' || LEVEL1)
l_log = SET_LOG('Level change: '          || LEVEL_CHANGE)
l_log = SET_LOG('PRO flag: '              || PRO)

/*============================================================================
  CONDICION
  Se determina la condicion del empleado en orden de prioridad:
  Promotion (solo si PRO = 'PRO'), NewHire, NonPerm o None
============================================================================*/
L_CINCO_MESES = ADD_MONTHS(L_PL_END_DATE, -5)

IF PRO = 'PRO' THEN
    L_CONDICION = 'Promotion'
ELSE IF L_HIRE_DATE >= L_CINCO_MESES AND (L_ACTION = 'HIRE' OR L_ACTION = 'ADD_ASSIGN') THEN
    L_CONDICION = 'NewHire'
ELSE IF L_TIPO_CONTRATO = '2' THEN
    L_CONDICION = 'NonPerm'
ELSE
    L_CONDICION = 'None'

l_log = SET_LOG('Condicion: ' || L_CONDICION)

/*============================================================================
  CONSTRUCCION DE CLAVE UDT
  Mismo alcance que Colombia (R1): todas las condiciones excepto
  Promotion y Salida comparan Incremento Legal contra el umbral
  correspondiente (Minimo Rango 1 o Mitad de Incremento Promedio) y
  sufijan L_CLAVE con el resultado. Debe coincidir exactamente con la
  clave construida en GB_CMP_INCRM_MERITO_RANGO y GB_CMP_INCRM_MERITO_MIN.
============================================================================*/
IF L_CONDICION = 'Promotion' AND (L_EVAL_TXT = 'Sobresaliente' OR L_EVAL_TXT = 'N/A') THEN
    L_CLAVE = 'Sobresaliente_PROM'
ELSE IF L_CONDICION = 'Promotion' AND (L_EVAL_TXT = 'Supera' OR L_EVAL_TXT = 'N/A') THEN 
    L_CLAVE = 'Supera_PROM'
ELSE IF L_CONDICION = 'Promotion' AND (L_EVAL_TXT = 'Cumple con lo esperado' OR L_EVAL_TXT = 'N/A') THEN 
    L_CLAVE = 'Cumple con lo esperado_PROM'
ELSE IF L_CONDICION = 'Promotion' THEN 
    L_CLAVE = 'Promotion'
ELSE IF L_CONDICION = 'Promotion' AND L_EVAL_TXT = 'N/A' THEN 
    L_CLAVE = 'Promotion'
ELSE IF L_CONDICION = 'NonPerm' THEN
(
    IF L_INCR_LEGAL > L_MIN_R1 THEN
        L_CLAVE = 'NonPerm_GE_MINR1'
    ELSE
        L_CLAVE = 'NonPerm_LT_MINR1'
)
ELSE IF L_CONDICION = 'NewHire' THEN
(
    IF L_INCR_LEGAL > L_MIN_R1 THEN
        L_CLAVE = 'NewHire_GE_MINR1'
    ELSE
        L_CLAVE = 'NewHire_LT_MINR1'
)
ELSE IF L_EVAL_TXT = 'N/A' THEN
(
    IF L_INCR_LEGAL > L_MIN_R1 THEN
        L_CLAVE = 'SinEval_GE_MINR1'
    ELSE
        L_CLAVE = 'SinEval_LT_MINR1'
)
ELSE IF L_EVAL_TXT = 'Salida' THEN
    L_CLAVE = 'Salida'
ELSE IF L_EVAL_TXT = 'Necesita Mejora' THEN
(
    IF L_INCR_LEGAL > L_MITAD_PROM THEN
        L_CLAVE = 'Necesita Mejora_GE_MITADPROM'
    ELSE
        L_CLAVE = 'Necesita Mejora_LT_MITADPROM'
)
ELSE IF L_EVAL_TXT = 'Por debajo de lo esperado' THEN
(
    IF L_INCR_LEGAL > L_MITAD_PROM THEN
        L_CLAVE = 'Por debajo de lo esperado_GE_MITADPROM'
    ELSE
        L_CLAVE = 'Por debajo de lo esperado_LT_MITADPROM'
)
ELSE IF L_EVAL_TXT = 'Sobresaliente' AND L_APERTURA <= 100 THEN
    L_CLAVE = 'Sobresaliente_LT100'
ELSE IF L_EVAL_TXT = 'Sobresaliente' AND L_APERTURA > 100 THEN
(
    IF L_INCR_LEGAL > L_MIN_R1 THEN
        L_CLAVE = 'Sobresaliente_GE100_GE_MINR1'
    ELSE
        L_CLAVE = 'Sobresaliente_GE100_LT_MINR1'
)
ELSE IF L_EVAL_TXT = 'Cumple con lo esperado' AND L_APERTURA <= 100 THEN
(
    IF L_INCR_LEGAL > L_MIN_R1 THEN
        L_CLAVE = 'Cumple con lo esperado_LT100_GE_MINR1'
    ELSE
        L_CLAVE = 'Cumple con lo esperado_LT100_LT_MINR1'
)
ELSE IF L_EVAL_TXT = 'Cumple con lo esperado' AND L_APERTURA > 100 THEN
(
    IF L_INCR_LEGAL > L_MIN_R1 THEN
        L_CLAVE = 'Cumple con lo esperado_GE100_GE_MINR1'
    ELSE
        L_CLAVE = 'Cumple con lo esperado_GE100_LT_MINR1'
)
ELSE IF L_EVAL_TXT = 'Supera' AND L_APERTURA <= 100 THEN
    L_CLAVE = 'Supera_LT100'
ELSE IF L_EVAL_TXT = 'Supera' AND L_APERTURA > 100 THEN
    L_CLAVE = 'Supera_GE100'
ELSE
    L_CLAVE = 'SinClasificar n/a'

l_log = SET_LOG('Clave UDT: ' || L_CLAVE)

/*============================================================================
  LECTURA UDT
  Se obtiene el indicador Rango_Maximo desde GB_CMP_RANGOS_MERITO
  usando la clave construida
============================================================================*/
L_RANGO_MAX = GET_TABLE_VALUE('GB_CMP_RANGOS_MERITO', 'Rango_Maximo', L_CLAVE)
l_log = SET_LOG('Rango Max: ' || L_RANGO_MAX)

/*============================================================================
  CALCULO VALORES NUMERICOS POR RANGO
  Se calculan los valores de R1 a R4 segun el tramo del promedio
============================================================================*/
IF L_PROM > 10 THEN
(
    L_VAL_R1_MIN = L_PROM - 3
    L_VAL_R2_MIN = L_PROM - 1.5
    L_VAL_R3_MIN = L_PROM
    L_VAL_R4_MIN = L_PROM + 1.5
    L_VAL_R1 = L_PROM - 1.5
    L_VAL_R2 = L_PROM
    L_VAL_R3 = L_PROM + 1.5
    L_VAL_R4 = L_PROM + 3
    L_VAL_R4_MAX = L_PROM + 3
)
ELSE IF L_PROM >= 5 AND L_PROM <= 10 THEN
(
    L_VAL_R1_MIN = L_PROM * 0.70
    L_VAL_R2_MIN = L_PROM * 0.85
    L_VAL_R3_MIN = L_PROM
    L_VAL_R4_MIN = L_PROM * 1.15
    L_VAL_R1 = L_PROM * 0.85
    L_VAL_R2 = L_PROM
    L_VAL_R3 = L_PROM * 1.15
    L_VAL_R4 = L_PROM * 1.30
    L_VAL_R4_MAX = L_PROM * 1.30
)
ELSE
(
    L_VAL_R1_MIN = L_PROM - 1.5
    L_VAL_R2_MIN = L_PROM - 0.75
    L_VAL_R3_MIN = L_PROM
    L_VAL_R4_MIN = L_PROM + 0.75
    L_VAL_R1 = L_PROM - 0.75
    L_VAL_R2 = L_PROM
    L_VAL_R3 = L_PROM + 0.75
    L_VAL_R4 = L_PROM + 1.5
    L_VAL_R4_MAX = L_PROM + 1.5
)

l_log = SET_LOG('Val R1: ' || TO_CHAR(L_VAL_R1))
l_log = SET_LOG('Val R2: ' || TO_CHAR(L_VAL_R2))
l_log = SET_LOG('Val R3: ' || TO_CHAR(L_VAL_R3))
l_log = SET_LOG('Val R4: ' || TO_CHAR(L_VAL_R4))
l_log = SET_LOG('Val R1_MIN: ' || TO_CHAR(L_VAL_R1_MIN))
l_log = SET_LOG('Val R2_MIN: ' || TO_CHAR(L_VAL_R2_MIN))
l_log = SET_LOG('Val R3_MIN: ' || TO_CHAR(L_VAL_R3_MIN))
l_log = SET_LOG('Val R4_MIN: ' || TO_CHAR(L_VAL_R4_MIN))
/*============================================================================
  RESOLUCION NUMERICA MINIMO
  Se traduce el indicador Rango_Min a su valor numerico correspondiente
============================================================================*/
IF L_RANGO_MAX = 'NO' THEN
    L_DEFAULT_MAX = 0
ELSE IF L_RANGO_MAX = 'R0_MIN' THEN
    L_DEFAULT_MAX = 0
ELSE IF L_RANGO_MAX = 'R0_MAX' THEN
    L_DEFAULT_MAX = L_VAL_R1
ELSE IF L_RANGO_MAX = 'R1_MIN' OR L_RANGO_MAX = 'R1' THEN
    L_DEFAULT_MAX = L_VAL_R1
ELSE IF L_RANGO_MAX = 'R1_MAX' THEN
    L_DEFAULT_MAX = L_VAL_R2
ELSE IF L_RANGO_MAX = 'R2_MIN' OR L_RANGO_MAX = 'R2' THEN
    L_DEFAULT_MAX = L_VAL_R2
ELSE IF L_RANGO_MAX = 'R2_MAX' THEN
    L_DEFAULT_MAX = L_VAL_R2
ELSE IF L_RANGO_MAX = 'R3_MIN' OR L_RANGO_MAX = 'R3' THEN
    L_DEFAULT_MAX = L_VAL_R3
ELSE IF L_RANGO_MAX = 'R3_MAX' THEN
    L_DEFAULT_MAX = L_VAL_R3
ELSE IF L_RANGO_MAX = 'R4_MIN' OR L_RANGO_MAX = 'R4' THEN
    L_DEFAULT_MAX = L_VAL_R4
ELSE IF L_RANGO_MAX = 'R4_MAX' THEN
    L_DEFAULT_MAX = L_VAL_R4_MAX
ELSE IF L_RANGO_MAX = 'PROM' THEN
    L_DEFAULT_MAX = L_PROM
ELSE IF L_RANGO_MAX = 'HALF_PROM' THEN
    L_DEFAULT_MAX = L_PROM / 2
ELSE IF L_RANGO_MAX = 'MITAD' THEN
    L_DEFAULT_MAX = L_PROM / 2
ELSE IF L_RANGO_MAX = 'INC_LG' THEN
    L_DEFAULT_MAX = L_INCR_LEGAL
ELSE
    L_DEFAULT_MAX = 0

l_log = SET_LOG('*** RESULTADO MAX: ' || TO_CHAR(L_DEFAULT_MAX) || ' ***')
RETURN L_DEFAULT_MAX