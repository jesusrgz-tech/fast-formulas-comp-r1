/******************************************************************************
* *
* FORMULA NAME      : GB_CMP_DIAS_BONO_MERITO_R1
* FORMULA TYPE      : Compensation Default and Override
* DESCRIPTION       : Retorna los dias de bono por merito para R4 (Espana,
*                     Portugal, Marruecos) segun el Legal Employer desde UDT.
*                     Aplica solo para niveles 4 y 5 con calificacion
*                     Sobresaliente. Selecciona UDT segun idioma derivado
*                     del Legal Employer.
* *
*-----------------------------------------------------------------------------*
* CREATED BY        : IT-GLOBAL                                               *
* CREATION DATE     : 07-Abril-2026                                           *
* LAST UPDATE DATE  : 27-Mayo-2026                                            *
* *
*******************************************************************************
* Change History:                                                             *
* Name              Date             Version          Comments                *
*-----------------------------------------------------------------------------*
* It Global         07-Abril-2026    1                Version Inicial         *
* It Global         27-Mayo-2026     2                Adaptacion R4: logica   *
*                                                     idioma ES_PT vs MAR,    *
*                                                     validacion nivel 4 y 5  *
* *
******************************************************************************/

INPUTS ARE CMP_IV_PLAN_START_DATE (text),
CMP_IV_PLAN_END_DATE (text),
CMP_IVR_ASSIGNMENT_ID(NUMBER_NUMBER),
CMP_IV_PLAN_EXTRACTION_DATE (text)

DEFAULT FOR PER_ASG_JOB_MANAGER_LEVEL IS 'N/ML'
DEFAULT FOR PER_ASG_ORG_LEGAL_EMPLOYER_NAME IS 'N/LE'

DEFAULT_DATA_VALUE FOR CMP_EXTERNAL_WORKER_DATA_RGE_ASG_VALUE1 IS 'N/A'
DEFAULT_DATA_VALUE FOR CMP_EXTERNAL_WORKER_DATA_RGE_ASG_SEQUENCE_NUMBER IS 0
DEFAULT_DATA_VALUE FOR CMP_EXTERNAL_WORKER_DATA_RGE_ASG_ASSIGNMENT_ID IS 0

HR_EXTRACT_DATE = TO_DATE(CMP_IV_PLAN_EXTRACTION_DATE, 'YYYY/MM/DD')

l_log = SET_LOG('*** INICIO GB_CMP_DIAS_BONO_MERITO_R4 ***')

/***** NIVEL Y LEGAL EMPLOYER *****/
CHANGE_CONTEXTS(EFFECTIVE_DATE = HR_EXTRACT_DATE)
(
    L_NIVEL = PER_ASG_JOB_MANAGER_LEVEL
    L_LEGAL_EMPLOYER = PER_ASG_ORG_LEGAL_EMPLOYER_NAME
)

l_log = SET_LOG('Nivel: ' || L_NIVEL)
l_log = SET_LOG('Legal Employer: ' || L_LEGAL_EMPLOYER)

/* ============ VALIDAR NIVEL 4 O 5 EXCLUSIVAMENTE ============ */
L_NIVEL_NUM = TO_NUMBER(L_NIVEL)
IF L_NIVEL_NUM < 4 OR L_NIVEL_NUM > 5 THEN
(
    l_log = SET_LOG('Nivel fuera de rango (requiere 4 o 5 exclusivamente), retorna 0')
    L_DEFAULT_VALUE = '0'
    RETURN L_DEFAULT_VALUE
)

/* ============ DETERMINAR IDIOMA POR LEGAL EMPLOYER ============ */


/* =================================================== EVALUACION ======================================================*/
L_EVAL_TXT = 'N/A'
L_EVAL_MAPPED = 'N/A'
L_IDX = 0

CHANGE_CONTEXTS(EFFECTIVE_DATE = HR_EXTRACT_DATE, COMPENSATION_RECORD_TYPE = 'CMP_MERITO')
(
    L_IDX = CMP_EXTERNAL_WORKER_DATA_RGE_ASG_SEQUENCE_NUMBER.LAST(-1)
    l_log = SET_LOG('Registros external data: ' || TO_CHAR(L_IDX))

    WHILE L_IDX >= 1 LOOP
    (
        L_EXT_VAL = CMP_EXTERNAL_WORKER_DATA_RGE_ASG_VALUE1[L_IDX]
        l_log = SET_LOG('VALUE1[' || TO_CHAR(L_IDX) || ']: ' || L_EXT_VAL)

        IF L_EXT_VAL != 'N/A' THEN
        (
                L_EVAL_MAPPED = GET_TABLE_VALUE('GB_CMP_LAC_LAS_CALIFICAC_MERITO', 'Calificacion_Texto', L_EXT_VAL)
           

            l_log = SET_LOG('Mapped: ' || L_EVAL_MAPPED)

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

/*========================================= VALIDAR CALIFICACION EN UDT ==========================================*/
    L_APLICA_BONO = GET_TABLE_VALUE('GB_CMP_LAC_LAS_CALIF_BONO', 'Aplica_Bono', L_EVAL_TXT)


l_log = SET_LOG('Aplica Bono: ' || L_APLICA_BONO)

IF L_APLICA_BONO = 'N/A' OR L_APLICA_BONO <> 'S' THEN
(
    l_log = SET_LOG('Calificacion ' || L_EVAL_TXT || ' no aplica bono, retorna 0')
    L_DEFAULT_VALUE = '0'
    RETURN L_DEFAULT_VALUE
)

/***** LEER DIAS DE BONO DEL UDT *****/
l_log = SET_LOG('Key UDT: [' || L_LEGAL_EMPLOYER || ']')

    L_DIAS_BONO = TO_NUMBER(GET_TABLE_VALUE('GB_CMP_LAC_LAS_DIAS_BONO_BASE_EVALUACION', 'Calificacion', L_LEGAL_EMPLOYER))

l_log = SET_LOG('*** RESULTADO DIAS BONO: ' || TO_CHAR(L_DIAS_BONO) || ' ***')

L_DEFAULT_VALUE = TO_CHAR(L_DIAS_BONO)
RETURN L_DEFAULT_VALUE