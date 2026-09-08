/******************************************************************************
* FORMULA NAME      : GB_CMP_TIPO_CONTRATO_DESC_R1                          *
* FORMULA TYPE      : Compensation Default and Override                       *
* DESCRIPTION       : Retorna la descripcion del tipo de contrato             *
*                     del colaborador a partir de PER_ASG_ATTRIBUTE1,         *
*                     considerando el catalogo completo de codigos de LAC/LAS.*
*-----------------------------------------------------------------------------*
* CREATED BY        : IT-GLOBAL                                               *
* CREATION DATE     : 08-Junio-2026                                           *
* LAST UPDATE DATE  : 13-Julio-2026                                           *
*-----------------------------------------------------------------------------*
* Change History:                                                             *
* Author          | Date            | Ver | Comments                          *
*-----------------+-----------------+-----+-----------------------------------*
* IT Global       | 08-Junio-2026   |  1  | Version Inicial                   *
* IT Global       | 08-Junio-2026   |  2  | Mapeo completo ESP/MOR/PT         *
* IT Global       | 13-Julio-2026   |  3  | Mapeo completo catalogo R1 (LAC/LAS) *
******************************************************************************/

INPUTS ARE CMP_IV_PLAN_START_DATE (text),

CMP_IV_PLAN_END_DATE (text),

CMP_IVR_ASSIGNMENT_ID (NUMBER_NUMBER),

CMP_IV_PLAN_EXTRACTION_DATE (text)

DEFAULT FOR PER_ASG_ATTRIBUTE1 IS 'N/A'

HR_EXTRACT_DATE = TO_DATE(CMP_IV_PLAN_EXTRACTION_DATE, 'YYYY/MM/DD')

l_log = SET_LOG('*** INICIO GB_CMP_TIPO_CONTRATO_DESC_R1 ***')

CHANGE_CONTEXTS(EFFECTIVE_DATE = HR_EXTRACT_DATE)
(
    L_CODE = PER_ASG_ATTRIBUTE1
)

l_log = SET_LOG('Attribute1 raw: ' || L_CODE)

/* ── Argentina ── */
IF L_CODE = 'AR22' THEN
    L_RESULT = 'PERMANENTE'
ELSE IF L_CODE = 'AR24' THEN
    L_RESULT = 'PERMANENTE'
ELSE IF L_CODE = 'FA8' THEN
    L_RESULT = 'PERMANENTE'
ELSE IF L_CODE = 'AR25' THEN
    L_RESULT = 'NO PERMANENTE'
ELSE IF L_CODE = 'FA12' THEN
    L_RESULT = 'NO PERMANENTE'
ELSE IF L_CODE = 'FA14' THEN
    L_RESULT = 'NO PERMANENTE'
ELSE IF L_CODE = 'FA22' THEN
    L_RESULT = 'NO PERMANENTE'

/* ── Chile ── */
ELSE IF L_CODE = 'CL20' THEN
    L_RESULT = 'PERMANENTE'
ELSE IF L_CODE = 'CL21' THEN
    L_RESULT = 'PERMANENTE'
ELSE IF L_CODE = 'CL22' THEN
    L_RESULT = 'NO PERMANENTE'

/* ── Colombia ── */
ELSE IF L_CODE = '00007' THEN
    L_RESULT = 'PERMANENTE'
ELSE IF L_CODE = 'CO01' THEN
    L_RESULT = 'PERMANENTE'
ELSE IF L_CODE = 'CO02' THEN
    L_RESULT = 'PERMANENTE'
ELSE IF L_CODE = 'CO03' THEN
    L_RESULT = 'PERMANENTE'
ELSE IF L_CODE = 'CO04' THEN
    L_RESULT = 'PERMANENTE'

/* ── Costa Rica ── */
ELSE IF L_CODE = 'CR1' THEN
    L_RESULT = 'PERMANENTE'
ELSE IF L_CODE = 'CR2' THEN
    L_RESULT = 'NO PERMANENTE'

/* ── Ecuador ── */
ELSE IF L_CODE = '00005' THEN
    L_RESULT = 'PERMANENTE'
ELSE IF L_CODE = 'EC02' THEN
    L_RESULT = 'PERMANENTE'
ELSE IF L_CODE = '00020' THEN
    L_RESULT = 'NO PERMANENTE'
ELSE IF L_CODE = '00022' THEN
    L_RESULT = 'NO PERMANENTE'
ELSE IF L_CODE = '00023' THEN
    L_RESULT = 'NO PERMANENTE'

/* ── El Salvador ── */
ELSE IF L_CODE = 'SV1' THEN
    L_RESULT = 'PERMANENTE'

/* ── Guatemala ── */
ELSE IF L_CODE = 'GU2' THEN
    L_RESULT = 'PERMANENTE'

/* ── Honduras ── */
ELSE IF L_CODE = 'HN1' THEN
    L_RESULT = 'PERMANENTE'

/* ── Mexico ── */
ELSE IF L_CODE = 'MEX2' THEN
    L_RESULT = 'PERMANENTE'
ELSE IF L_CODE = 'MEX4' THEN
    L_RESULT = 'PERMANENTE'
ELSE IF L_CODE = 'MEX1' THEN
    L_RESULT = 'NO PERMANENTE'
ELSE IF L_CODE = 'MEX3' THEN
    L_RESULT = 'NO PERMANENTE'
ELSE IF L_CODE = 'MEX5' THEN
    L_RESULT = 'NO PERMANENTE'

/* ── Nicaragua ── */
ELSE IF L_CODE = 'NI2' THEN
    L_RESULT = 'PERMANENTE'

/* ── Panama ── */
ELSE IF L_CODE = 'PA01' THEN
    L_RESULT = 'PERMANENTE'
ELSE IF L_CODE = 'PA03' THEN
    L_RESULT = 'PERMANENTE'
ELSE IF L_CODE = 'PA05' THEN
    L_RESULT = 'PERMANENTE'
ELSE IF L_CODE = 'PA11' THEN
    L_RESULT = 'PERMANENTE'
ELSE IF L_CODE = 'PA12' THEN
    L_RESULT = 'PERMANENTE'
ELSE IF L_CODE = 'PA13' THEN
    L_RESULT = 'PERMANENTE'
ELSE IF L_CODE = 'PA15' THEN
    L_RESULT = 'PERMANENTE'

/* ── Paraguay ── */
ELSE IF L_CODE = 'PY2' THEN
    L_RESULT = 'PERMANENTE'
ELSE IF L_CODE = 'PY1' THEN
    L_RESULT = 'NO PERMANENTE'

/* ── Peru ── */
ELSE IF L_CODE = 'PE01' THEN
    L_RESULT = 'PERMANENTE'
ELSE IF L_CODE = 'PE02' THEN
    L_RESULT = 'PERMANENTE'
ELSE IF L_CODE = 'PE06' THEN
    L_RESULT = 'PERMANENTE'
ELSE IF L_CODE = 'PE03' THEN
    L_RESULT = 'NO PERMANENTE'
ELSE IF L_CODE = 'PE05' THEN
    L_RESULT = 'NO PERMANENTE'

/* ── Uruguay ── */
ELSE IF L_CODE = 'UY01' THEN
    L_RESULT = 'PERMANENTE'
ELSE IF L_CODE = 'UY03' THEN
    L_RESULT = 'PERMANENTE'
ELSE IF L_CODE = 'UY07' THEN
    L_RESULT = 'PERMANENTE'
ELSE IF L_CODE = 'UY09' THEN
    L_RESULT = 'PERMANENTE'
ELSE IF L_CODE = 'UY10' THEN
    L_RESULT = 'PERMANENTE'
ELSE IF L_CODE = 'UY11' THEN
    L_RESULT = 'PERMANENTE'
ELSE IF L_CODE = 'UY02' THEN
    L_RESULT = 'NO PERMANENTE'
ELSE IF L_CODE = 'UY04' THEN
    L_RESULT = 'NO PERMANENTE'
ELSE IF L_CODE = 'UY05' THEN
    L_RESULT = 'NO PERMANENTE'
ELSE IF L_CODE = 'UY06' THEN
    L_RESULT = 'NO PERMANENTE'

ELSE
    L_RESULT = 'N/A'

l_log = SET_LOG('*** RESULTADO TIPO_CONTRATO: ' || L_RESULT || ' ***')

RETURN L_RESULT