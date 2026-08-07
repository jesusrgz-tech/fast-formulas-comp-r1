/******************************************************************************
* FORMULA NAME      : GB_CMP_TIPO_CONTRATO_R1                               *
* FORMULA TYPE      : Compensation Default and Override                       *
* DESCRIPTION       : Retorna el tipo de contrato del colaborador.            *
*                     Lee PER_ASG_ATTRIBUTE1 directamente sin mapeo,          *
*                     agnostico a pais dentro de Region 1.                    *
*-----------------------------------------------------------------------------*
* CREATED BY        : IT-GLOBAL                                               *
* CREATION DATE     : 13-Julio-2026                                           *
* LAST UPDATE DATE  : 13-Julio-2026                                           *
*-----------------------------------------------------------------------------*
* Change History:                                                             *
* Author          | Date            | Ver | Comments                          *
*-----------------+-----------------+-----+-----------------------------------*
* IT Global       | 13-Julio-2026   |  1  | Version Inicial, adaptada de R4   *
******************************************************************************/

INPUTS ARE CMP_IV_PLAN_START_DATE (text),
CMP_IV_PLAN_END_DATE (text),
CMP_IVR_ASSIGNMENT_ID (NUMBER_NUMBER),
CMP_IV_PLAN_EXTRACTION_DATE (text)

DEFAULT FOR PER_ASG_ATTRIBUTE1 IS 'PERMANENTE'

HR_EXTRACT_DATE = TO_DATE(CMP_IV_PLAN_EXTRACTION_DATE, 'YYYY/MM/DD')

l_log = SET_LOG('*** INICIO GB_CMP_TIPO_CONTRATO_R1 ***')

/***** TIPO DE CONTRATO *****/
CHANGE_CONTEXTS(EFFECTIVE_DATE = HR_EXTRACT_DATE)
(
    L_TIPO_CONTRATO = PER_ASG_ATTRIBUTE1
)

    L_DEFAULT_VALUE = L_TIPO_CONTRATO

l_log = SET_LOG('*** RESULTADO TIPO_CONTRATO: ' || (L_DEFAULT_VALUE) || ' ***')
RETURN L_DEFAULT_VALUE