/******************************************************************************
* *
* FORMULA NAME      : GB_CMP_INC_PLAN_SALARIAL_PCT
* FORMULA TYPE      : Compensation Default and Override
* DESCRIPTION       : Retorna el porcentaje de incremento del plan salarial
*                     para R4 (Espana, Portugal, Marruecos) desde UDT
*                     GB_CMP_INC_PLAN_SALARIAL usando key por pais derivada
*                     del Legal Employer.
* *
*-----------------------------------------------------------------------------*
* CREATED BY        : IT-GLOBAL                                               *
* CREATION DATE     : 27-Mayo-2026                                            *
* LAST UPDATE DATE  : 27-Mayo-2026                                            *
* *
*******************************************************************************
* Change History:                                                             *
* Name              Date             Version          Comments                *
*-----------------------------------------------------------------------------*
* It Global         27-Mayo-2026     1                Version Inicial R4      *
* *
******************************************************************************/

INPUTS ARE
CMP_IV_PLAN_EXTRACTION_DATE (text)

DEFAULT FOR CMP_IV_PLAN_EXTRACTION_DATE IS '4012/01/01'
DEFAULT FOR PER_ASG_ORG_LEGAL_EMPLOYER_NAME IS 'N/LE'

HR_EXTRACT_DATE = TO_DATE(CMP_IV_PLAN_EXTRACTION_DATE, 'YYYY/MM/DD')

l_log = SET_LOG('*** INICIO GB_CMP_INC_PLAN_SALARIAL_PCT_R4 ***')

/***** LEGAL EMPLOYER *****/
CHANGE_CONTEXTS(EFFECTIVE_DATE = HR_EXTRACT_DATE)
(
    L_LEGAL_EMPLOYER = PER_ASG_ORG_LEGAL_EMPLOYER_NAME
)

l_log = SET_LOG('Legal Employer: ' || L_LEGAL_EMPLOYER)

/* ============ MAPEO LEGAL EMPLOYER A KEY UDT ============ */
IF L_LEGAL_EMPLOYER = 'Bimbo de Colombia, S.A.' THEN
    L_KEY_UDT = 'CO'
ELSE IF L_LEGAL_EMPLOYER = 'Bimbo Ecuador S.A.' THEN
    L_KEY_UDT = 'EC'
ELSE IF L_LEGAL_EMPLOYER = 'Bimbo de Costa Rica, S.A.' THEN
    L_KEY_UDT = 'CR'
ELSE IF L_LEGAL_EMPLOYER = 'Barcel  de El Salvador, S.A. de C.V.' OR L_LEGAL_EMPLOYER = 'Bimbo de El Salvador, S.A. de C.V.' THEN
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
    L_KEY_UDT = 'DEFAULT' /* O el valor por defecto que manejes */



l_log = SET_LOG('Key UDT: ' || L_KEY_UDT)

/************************** OBTENER VALOR DE UDT ****************************/
L_VALOR_RAW = GET_TABLE_VALUE('GB_CMP_LAC_LAS_INC_PLAN_SALARIAL', 'Valor_Inc_Plan_Salarial', L_KEY_UDT)

l_log = SET_LOG('Valor UDT RAW: ' || L_VALOR_RAW)

/* VALIDACION TEXTO VACIO */
IF L_VALOR_RAW = ' ' THEN
(
    l_log = SET_LOG('Valor vacio, retorna 0')
    L_DEFAULT_VALUE = 0
    RETURN L_DEFAULT_VALUE
)

/* CONVERSION */
L_VALOR_NUM = TO_NUMBER(L_VALOR_RAW)

l_log = SET_LOG('Valor Num: ' || TO_CHAR(L_VALOR_NUM))

/* VALIDACIONES */
IF L_VALOR_NUM < 0 OR L_VALOR_NUM > 100 THEN
(
    l_log = SET_LOG('Valor fuera de rango [0-100], retorna 0')
    L_DEFAULT_VALUE = 0
    RETURN L_DEFAULT_VALUE
)

/* RESULTADO FINAL */
L_DEFAULT_VALUE = L_VALOR_NUM
l_log = SET_LOG('*** RESULTADO GB_CMP_INC_PLAN_SALARIAL_PCT_R1: ' || TO_CHAR(L_DEFAULT_VALUE) || ' ***')
RETURN L_DEFAULT_VALUE