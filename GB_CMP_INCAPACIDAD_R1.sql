/******************************************************************************
* FORMULA NAME      : GB_CMP_INCAPACIDAD_R1                                   *
* FORMULA TYPE      : Compensation Default and Override                       *
* DESCRIPTION       : Retorna 0 en % Incremento si el colaborador tiene      *
*                     registro de incapacidad (CMP_INCAPACIDAD) con valor    *
*                     'SI' en VALUE1. Si no hay incapacidad lee el valor     *
*                     de datos externos CMP_MERITO_INCRE VALUE1 y lo retorna *
*                     como % Incremento. Si no hay registro CMP_MERITO_INCRE *
*                     retorna 0.                                              *
*-----------------------------------------------------------------------------*
* CREATED BY        : IT-GLOBAL                                               *
* CREATION DATE     : 08-Mayo-2026                                            *
* LAST UPDATE DATE  : 29-Mayo-2026                                            *
*-----------------------------------------------------------------------------*
* Change History:                                                             *
* Author          | Date            | Ver | Comments                          *
*-----------------+-----------------+-----+-----------------------------------*
* IT Global       | 08-Mayo-2026    |  1  | Version Inicial                   *
* IT Global       | 27-Mayo-2026    |  2  | Adaptacion R4: key por pais       *
*                 |                 |     | MOR/ESP/PT desde Legal Employer,  *
*                 |                 |     | correccion nombre UDT             *
* IT Global       | 29-Mayo-2026    |  3  | Logica incapacidad: retorna 0 si  *
*                 |                 |     | CMP_INCAPACIDAD VALUE1 = 'SI',    *
*                 |                 |     | retorna valor CMP_MERITO_INCRE    *
*                 |                 |     | VALUE1 en caso contrario; retorna *
*                 |                 |     | 0 si no hay registro externo      *
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
DEFAULT FOR PER_ASG_ORG_LEGAL_EMPLOYER_NAME IS 'N/LE'

/*============================================================================
  FECHAS BASE
============================================================================*/
HR_EXTRACT_DATE = TO_DATE(CMP_IV_PLAN_EXTRACTION_DATE, 'YYYY/MM/DD')

l_log = SET_LOG('*** INICIO GB_CMP_INCAPACIDAD_R4 ***')
L_ASG_ID = CMP_IVR_ASSIGNMENT_ID[1]
l_log = SET_LOG('Assignment ID: ' || TO_CHAR(L_ASG_ID))

/*============================================================================
  LEGAL EMPLOYER Y KEY UDT POR PAIS
============================================================================*/
CHANGE_CONTEXTS(EFFECTIVE_DATE = HR_EXTRACT_DATE)
(
    L_LEGAL_EMPLOYER = PER_ASG_ORG_LEGAL_EMPLOYER_NAME
)

l_log = SET_LOG('Legal Employer: ' || L_LEGAL_EMPLOYER)

/*============================================================================
  LECTURA DATOS EXTERNOS INCAPACIDAD
============================================================================*/
L_INCAPACIDAD = 'N'
L_IDX = 0

CHANGE_CONTEXTS(EFFECTIVE_DATE = HR_EXTRACT_DATE, COMPENSATION_RECORD_TYPE = 'CMP_INCAPACIDAD')
(
    L_IDX = CMP_EXTERNAL_WORKER_DATA_RGE_ASG_SEQUENCE_NUMBER.LAST(-1)
    l_log = SET_LOG('Registros incapacidad: ' || TO_CHAR(L_IDX))

    WHILE L_IDX >= 1 LOOP
    (
        L_EXT_VAL = CMP_EXTERNAL_WORKER_DATA_RGE_ASG_VALUE1[L_IDX]
        l_log = SET_LOG('Valor incapacidad idx ' || TO_CHAR(L_IDX) || ': ' || L_EXT_VAL)

        IF L_EXT_VAL = 'Yes' THEN
        (
            L_INCAPACIDAD = 'Y'
            L_IDX = 0
        )
        ELSE
            L_IDX = L_IDX - 1
    )
)

l_log = SET_LOG('Incapacidad flag: ' || L_INCAPACIDAD)

/*============================================================================
  RESULTADO
  Si hay incapacidad retorna 0.
  Si no hay incapacidad retorna valor de CMP_MERITO_INCRE VALUE1.
  Si no hay registro CMP_MERITO_INCRE retorna 0.
============================================================================*/
IF L_INCAPACIDAD = 'Y' THEN
    L_DEFAULT_VALUE = 0
ELSE
(
    L_PCT_EXTERNO = 'N/A'
    L_IDX2 = 0

    CHANGE_CONTEXTS(EFFECTIVE_DATE = HR_EXTRACT_DATE, COMPENSATION_RECORD_TYPE = 'CMP_MERITO_INCRE')
    (
        L_IDX2 = CMP_EXTERNAL_WORKER_DATA_RGE_ASG_SEQUENCE_NUMBER.LAST(-1)
        l_log = SET_LOG('Registros merito externo: ' || TO_CHAR(L_IDX2))

        WHILE L_IDX2 >= 1 LOOP
        (
            L_EXT_VAL2 = CMP_EXTERNAL_WORKER_DATA_RGE_ASG_VALUE1[L_IDX2]
            l_log = SET_LOG('Valor merito externo idx ' || TO_CHAR(L_IDX2) || ': ' || L_EXT_VAL2)

            IF L_EXT_VAL2 != 'N/A' THEN
            (
                L_PCT_EXTERNO = L_EXT_VAL2
                L_IDX2 = 0
            )
            ELSE
                L_IDX2 = L_IDX2 - 1
        )
    )

    l_log = SET_LOG('PCT externo: ' || L_PCT_EXTERNO)

    IF L_PCT_EXTERNO != 'N/A' THEN
        L_DEFAULT_VALUE = TO_NUM(L_PCT_EXTERNO)
    ELSE
        L_DEFAULT_VALUE = 0
)

l_log = SET_LOG('*** RESULTADO PORCENTAJE: ' || TO_CHAR(L_DEFAULT_VALUE) || ' ***')
RETURN L_DEFAULT_VALUE