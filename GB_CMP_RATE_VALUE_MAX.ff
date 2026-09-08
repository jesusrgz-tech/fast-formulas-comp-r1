/**********************************************************************
FORMULA NAME      : GB_CMP_RATE_VALUE_MAX
CREATED_BY        : IT-GLOBAL
CREATION_DATE     : 
LAST_UPDATE_DATE  : 08 de Julio del 2026
FORMULA TYPE      : Compensation Default and Override
DESCRIPTION       : Obtiene el valor maximo del grado. Fecha de contexto
                    acotada al fin del ciclo del plan. Value Sets reciben
                    P_EFFECTIVE_DATE para no resolver contra SYSDATE real.
                    Loguea el nombre del Rate/Plan Salarial via Value Set
                    DEBUG_PLA_SALARIAL para facilitar auditoria en logs.
**********************************************************************/

INPUTS ARE CMP_IV_PLAN_EXTRACTION_DATE (text),
CMP_IV_PLAN_END_DATE (text),
CMP_IVR_ASSIGNMENT_ID (NUMBER_NUMBER)

DEFAULT FOR PER_ASG_GRADE_ID IS 123
DEFAULT FOR CMP_IV_PLAN_EXTRACTION_DATE IS '4012/01/01'
DEFAULT FOR CMP_IV_PLAN_END_DATE IS '4712/12/31'
DEFAULT FOR PER_ASG_PERSON_ID IS 0

L_DEFAULT_VALUE = 0
L_GRADE = 0
L_PARAM = 'NULL'
L_MAX = 0

HR_PLAN_END_DATE = TO_DATE(CMP_IV_PLAN_END_DATE, 'YYYY/MM/DD')
HR_EXTRACT_DATE = TO_DATE(CMP_IV_PLAN_EXTRACTION_DATE, 'YYYY/MM/DD')
L_PER_ID = PER_ASG_PERSON_ID

l_log = SET_LOG('*** INICIO GB_CMP_RATE_VALUE_MAX ***')
l_log = SET_LOG('Fecha extraccion: ' || TO_CHAR(HR_EXTRACT_DATE))
l_log = SET_LOG('Fecha fin de ciclo: ' || TO_CHAR(HR_PLAN_END_DATE))
l_log = SET_LOG('Person ID: ' || TO_CHAR(L_PER_ID))

L_ASG_ID = CMP_IVR_ASSIGNMENT_ID[1]
l_log = SET_LOG('Assignment ID: ' || TO_CHAR(L_ASG_ID))

/*=== INICIO DIAGNOSTICO NUEVO ===*/
L_CTX_ASG = GET_CONTEXT(HR_ASSIGNMENT_ID, -1)
l_log = SET_LOG('Assignment ID segun contexto interno (HR_ASSIGNMENT_ID): ' || TO_CHAR(L_CTX_ASG))
l_log = SET_LOG('Assignment ID segun input CMP_IVR: ' || TO_CHAR(L_ASG_ID))
/*=== FIN DIAGNOSTICO NUEVO ===*/

IF HR_EXTRACT_DATE > HR_PLAN_END_DATE THEN
(
    L_FECHA_CONTEXTO = HR_PLAN_END_DATE
    l_log = SET_LOG('Extraccion posterior al cierre del ciclo, se acota a fin de ciclo')
)
ELSE
(
    L_FECHA_CONTEXTO = HR_EXTRACT_DATE
)

l_log = SET_LOG('Fecha usada en CHANGE_CONTEXTS: ' || TO_CHAR(L_FECHA_CONTEXTO))

CHANGE_CONTEXTS(EFFECTIVE_DATE = L_FECHA_CONTEXTO)
(
    L_GRADE = PER_ASG_GRADE_ID
)

l_log = SET_LOG('Grade ID: ' || TO_CHAR(L_GRADE))

L_PARAM = '|=PERSON_ID=' || TO_CHAR(L_PER_ID) || '|P_ASSIGNMENT_ID=' || TO_CHAR(L_CTX_ASG) || '|P_EFFECTIVE_DATE=' || TO_CHAR(L_FECHA_CONTEXTO, 'YYYY/MM/DD')
L_RATE_ID = TO_NUM(GET_VALUE_SET('GB_CMP_ASG_RATE_ID', L_PARAM))
l_log = SET_LOG('Rate ID: ' || TO_CHAR(L_RATE_ID))


    L_PARAM_RATE_NAME = '|=P_RATE_ID=' || TO_CHAR(L_RATE_ID)
    L_RATE_NAME = GET_VALUE_SET('DEBUG_PLA_SALARIAL', L_PARAM_RATE_NAME)
    l_log = SET_LOG('Plan Salarial del SQL Extraction : ' || L_RATE_NAME)

IF L_RATE_ID > 0 THEN
(
    L_PARAM_RATE_NAME = '|=P_RATE_ID=' || TO_CHAR(L_RATE_ID)
    L_RATE_NAME = GET_VALUE_SET('DEBUG_PLA_SALARIAL', L_PARAM_RATE_NAME)
    l_log = SET_LOG('Plan Salarial entro a la rama de no tener rate id: ' || L_RATE_NAME)

    L_PARAM = '|=P_ASSIGNMENT_GRADE=' || TO_CHAR(L_GRADE) || '|P_ASSIGNMENT_RATE=' || TO_CHAR(L_RATE_ID) || '|P_EFFECTIVE_DATE=' || TO_CHAR(L_FECHA_CONTEXTO, 'YYYY/MM/DD')
    l_log = SET_LOG('Param (con Rate ID): ' || L_PARAM)
    L_MAX = TO_NUM(GET_VALUE_SET('GB_CMP_RATE_ID_VALUE_MAX', L_PARAM))
)
ELSE
(
    l_log = SET_LOG('Sin Rate ID, no se puede resolver Plan Salarial via DEBUG_PLA_SALARIAL')
    L_PARAM = '|=P_ASSIGNMENT_GRADE=' || TO_CHAR(L_GRADE) || '|P_EFFECTIVE_DATE=' || TO_CHAR(L_FECHA_CONTEXTO, 'YYYY/MM/DD')
    l_log = SET_LOG('Param (sin Rate ID, posible ambiguedad si Grade tiene varios Rates): ' || L_PARAM)
    L_MAX = TO_NUM(GET_VALUE_SET('GB_CMP_RATE_VALUE_MAX', L_PARAM))
)

l_log = SET_LOG('Max via Value Set: ' || TO_CHAR(L_MAX))

IF L_MAX = 0 THEN
    l_log = SET_LOG('Max regreso 0: puede ser gap de datos o valor legitimo, validar manualmente')

L_DEFAULT_VALUE = L_MAX

l_log = SET_LOG('*** RESULTADO MAX: ' || TO_CHAR(L_DEFAULT_VALUE) || ' ***')
RETURN L_DEFAULT_VALUE
