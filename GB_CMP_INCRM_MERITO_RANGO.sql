/******************************************************************************
* FORMULA NAME      : GB_CMP_INCRM_MERITO_RANGO                               *
* FORMULA TYPE      : Compensation Default and Override                       *
* DESCRIPTION       : Obtiene el texto del rango de incremento por merito     *
*                     leyendo directamente desde UDT GB_CMP_RANGOS_MERITO.    *
*                     La deteccion de Promotion se realiza mediante          *
*                     recorrido historico de PER_ASG_JOB_MANAGER_LEVEL        *
*                     dentro de la ventana de 5 meses previa al fin del plan *
*                     Condiciones A (Salida), B (Necesita Mejora / Por       *
*                     debajo de lo esperado) e I (SinEval) comparan          *
*                     Incremento_Legal (columna de GB_INCREMENTO_MERITO_V2,  *
*                     antes Inflacion_Minima) contra Minimo Rango 1 o Mitad  *
*                     de Incremento Promedio segun corresponda, y sufijan    *
*                     L_CLAVE con el resultado. La elegibilidad de Nivel 5+  *
*                     ya se valida en GB_CMP_ELEGIBILIDAD_BR aguas arriba,   *
*                     por lo que esta formula no repite ese gate.           *
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
* IT Global       | 14-Mayo-2026    |  3  | Replica logica retrofit promotion *
*                 |                 |     | por recorrido historico de nivel  *
* IT Global       | 01-Sept-2026    |  4  | Incremento Legal BR: comparacion  *
*                 |                 |     | en A/B/I contra Incremento_Legal  *
*                 |                 |     | (GB_INCREMENTO_MERITO_V2).        *
*                 |                 |     | Salida vs 0 PENDIENTE DE VALIDAR  *
*                 |                 |     | con funcionales.                  *
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

l_log = SET_LOG('*** INICIO GB_CMP_INCRM_MERITO_RANGO ***')
L_ASG_ID = CMP_IVR_ASSIGNMENT_ID[1]
l_log = SET_LOG('Assignment ID: ' || TO_CHAR(L_ASG_ID))

/*============================================================================
  PROMEDIO BR
  Se obtiene el incremento promedio desde GB_INCREMENTO_MERITO_V2
  para la clave BR
============================================================================*/
L_PROM = TO_NUMBER(GET_TABLE_VALUE('GB_INCREMENTO_MERITO_V2', 'Incremento_Promedio', 'BR'))
l_log = SET_LOG('Promedio BR: ' || TO_CHAR(L_PROM))

/*============================================================================
  INCREMENTO LEGAL BR
  Se obtiene desde GB_INCREMENTO_MERITO_V2, columna Incremento_Legal
  (antes Inflacion_Minima). Se calculan tambien los umbrales de
  comparacion Minimo Rango 1 y Mitad de Incremento Promedio, mismo
  patron ya validado en GB_CMP_INCRM_MERITO_RANGO_R1.
============================================================================*/
L_INCR_LEGAL = TO_NUMBER(GET_TABLE_VALUE('GB_INCREMENTO_MERITO_V2', 'Incremento_Legal', 'BR'))
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
  grado, sueldo, person ID y nivel de manager con contexto a la fecha
  de extraccion
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
l_log = SET_LOG('Manager Level actual: ' || MGR_LVL)

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
  sufijan L_CLAVE con el resultado. Promotion y Salida quedan planas,
  sin comparacion.
============================================================================*/
IF L_CONDICION = 'Promotion' THEN
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
  Se obtiene el texto del rango directamente desde GB_CMP_RANGOS_MERITO
  usando la clave construida
============================================================================*/
L_RANGO_OUTPUT = GET_TABLE_VALUE('GB_CMP_RANGOS_MERITO', 'Texto_Rango', L_CLAVE)

l_log = SET_LOG('*** RESULTADO RANGO: ' || L_RANGO_OUTPUT || ' ***')
RETURN L_RANGO_OUTPUT