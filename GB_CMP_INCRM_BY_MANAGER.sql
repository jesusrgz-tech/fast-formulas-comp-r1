/******************************************************************************
* FORMULA NAME      : GB_CMP_INCRM_BY_MANAGER                                 *
* FORMULA TYPE      : Compensation Default and Override                       *
* DESCRIPTION       : Devuelve el incremento promedio de merito por plan/pais *
*                     para el Budget Page. Resuelve dinamicamente el nombre   *
*                     del plan desde CMP_IV_PLAN_ID via Value Set             *
*                     GB_CMP_VS_PLAN_NAME y deriva la key de pais para leer   *
*                     el promedio desde UDT GB_INCREMENTO_MERITO.             *
*                     Formula unica para todos los planes R1.                 *
*-----------------------------------------------------------------------------*
* CREATED BY        : IT-GLOBAL                                               *
* CREATION DATE     : 14-Agosto-2026                                          *
* LAST UPDATE DATE  : 19-Agosto-2026                                          *
*-----------------------------------------------------------------------------*
* Change History:                                                             *
* Author          | Date            | Ver | Comments                          *
*-----------------+-----------------+-----+-----------------------------------*
* IT Global       | 14-Agosto-2026  |  1  | Version inicial (ESP/PT/MOR).     *
* IT Global       | 19-Agosto-2026  |  2  | Actualizacion a planes R1 y keys  *
*                 |                 |     | UDT correspondientes.             *
******************************************************************************/

INPUTS ARE CMP_IV_PLAN_ID (number),
CMP_IV_PLAN_START_DATE (text),
CMP_IV_PLAN_END_DATE (text),
CMP_IVR_ASSIGNMENT_ID (NUMBER_NUMBER),
CMP_IV_PLAN_EXTRACTION_DATE (text)

DEFAULT FOR CMP_IV_PLAN_ID IS 0

/*============================================================================
  INICIO
============================================================================*/
l_log = SET_LOG('*** INICIO GB_CMP_INCRM_BY_MANAGER ***')
l_log = SET_LOG('Plan ID: ' || TO_CHAR(CMP_IV_PLAN_ID))

/*============================================================================
  OBTENER PLAN NAME DESDE VALUE SET
  Value Set GB_CMP_VS_PLAN_NAME ejecuta:
    SELECT NAME FROM CMP_PLANS_VL WHERE PLAN_ID = :P_PLAN_ID
  Retorna el nombre del plan sin depender del ID fijo (portable entre pods).
============================================================================*/
L_PARAM_PLAN_NAME = '|=P_PLAN_ID=' || TO_CHAR(CMP_IV_PLAN_ID)
l_log = SET_LOG('DEBUG :' || L_PARAM_PLAN_NAME)

L_PLAN_NAME = GET_VALUE_SET('GB_CMP_VS_PLAN_NAME', L_PARAM_PLAN_NAME)

l_log = SET_LOG('Plan Name: ' || L_PLAN_NAME)

/*============================================================================
  DERIVAR KEY PAIS DESDE PLAN NAME
  Se usa el nombre del plan para determinar la key exacta de la UDT.
============================================================================*/
IF (
    L_PLAN_NAME = 'MXBAR Incremento por Mérito Final R1' OR
    L_PLAN_NAME = 'MXBIM Incremento por Mérito Final R1' OR
    L_PLAN_NAME = 'MXBIS Incremento por Mérito Final R1' OR
    L_PLAN_NAME = 'MXCBI Incremento por Mérito Final R1' OR
    L_PLAN_NAME = 'MXGB Incremento por Mérito Final R1'  OR
    L_PLAN_NAME = 'MXMOX Incremento por Mérito Final R1' OR
    L_PLAN_NAME = 'MXTPA Incremento por Mérito Final R1'
    ) THEN
(
    L_KEY_PAIS = 'MEX'
)
ELSE IF (
    L_PLAN_NAME = 'CRBCR Incremento por Mérito Final R1' OR
    L_PLAN_NAME = 'CRCSCB Incremento por Mérito Final R1') THEN
(
    L_KEY_PAIS = 'CR'
)
ELSE IF (
    L_PLAN_NAME = 'SVBLES Incremento por Mérito Final R1' OR
         L_PLAN_NAME = 'SVBES Incremento por Mérito Final R1') THEN
(
    L_KEY_PAIS = 'SV'
)
ELSE IF (L_PLAN_NAME = 'GTBCA Incremento por Mérito Final R1' OR
         L_PLAN_NAME = 'GTVCN Incremento por Mérito Final R1') THEN
(
    L_KEY_PAIS = 'GT'
)
ELSE IF (
    L_PLAN_NAME = 'HNBHO Incremento por Mérito Final R1' OR
    L_PLAN_NAME = 'HNCIL Incremento por Mérito Final R1') THEN
(
    L_KEY_PAIS = 'HN'
)
ELSE IF L_PLAN_NAME = 'NIBNI Incremento por Mérito Final R1' THEN
(
    L_KEY_PAIS = 'NI'
)
ELSE IF (
    L_PLAN_NAME = 'PABPA Incremento por Mérito Final R1' OR
    L_PLAN_NAME = 'PANUTA Incremento por Mérito Final R1') THEN
(
    L_KEY_PAIS = 'PA'
)
ELSE IF L_PLAN_NAME = 'ECBEC Incremento por Mérito Final R1' THEN
(
    L_KEY_PAIS = 'EC'
)
ELSE IF L_PLAN_NAME = 'COBCO Incremento por Mérito Final R1' THEN
(
    L_KEY_PAIS = 'CO'
)
ELSE IF L_PLAN_NAME = 'ARCAF Incremento por Mérito Final R1' THEN
(
    L_KEY_PAIS = 'AR'
)
ELSE IF (L_PLAN_NAME = 'CLID Incremento por Mérito Final R1' OR
         L_PLAN_NAME = 'CLBACL Incremento por Mérito Final R1') THEN
(
    L_KEY_PAIS = 'CL'
)
ELSE IF L_PLAN_NAME = 'PEBPE Incremento por Mérito Final R1' THEN
(
    L_KEY_PAIS = 'PE'
)
ELSE IF L_PLAN_NAME = 'UYBUY Incremento por Mérito Final R1' THEN
(
    L_KEY_PAIS = 'UY'
)
ELSE IF L_PLAN_NAME = 'PYBPY Incremento por Mérito Final R1' THEN
(
    L_KEY_PAIS = 'PY'
)
ELSE
(
    l_log = SET_LOG('ERROR: Plan Name no reconocido: ' || L_PLAN_NAME)
    L_KEY_PAIS = 'N/A'
)

l_log = SET_LOG('Key pais: ' || L_KEY_PAIS)

/*============================================================================
  PROMEDIO UDT
============================================================================*/
L_UDT_PROM = TO_NUM(GET_TABLE_VALUE('GB_CMP_LAC_LAS_INCREMENTO_MERITO', 'Incremento_Promedio', L_KEY_PAIS))

l_log = SET_LOG('Promedio UDT: ' || TO_CHAR(L_UDT_PROM))

/*============================================================================
  RESULTADO
============================================================================*/
l_log = SET_LOG('*** RESULTADO: ' || TO_CHAR(L_UDT_PROM) || ' ***')
RETURN L_UDT_PROM