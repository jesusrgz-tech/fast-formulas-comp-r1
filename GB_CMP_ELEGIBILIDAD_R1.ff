/*****************************************************************************
FORMULA NAME: GB_CMP_ELEGIBILIDAD_R1
CREATED_BY : IT-GLOBAL
CREATION_DATE : 07 de Abril del 2026
LAST_UPDATE_DATE : 22 de Junio del 2026
FORMULA TYPE : Participation and Rate Eligibility
DESCRIPTION : Elegibilidad para el plan MABMO Merito R4. Incluye
              colaboradores según su nivel de manager (>=6 para Colombia,
              >=4 para resto de entidades).
*****************************************************************************/

INPUTS ARE CMP_IV_PLAN_ELIG_DATE (text),
           CMP_IV_PLAN_END_DATE (text)

DEFAULT FOR CMP_IV_PLAN_ELIG_DATE IS '4012/01/01'
DEFAULT FOR CMP_IV_PLAN_END_DATE IS '4712/12/31'
DEFAULT FOR PER_ASG_JOB_MANAGER_LEVEL IS 'NO_MGR_LVL'
DEFAULT FOR PER_ASG_ATTRIBUTE1 IS 'N/A'
DEFAULT FOR PER_ASG_ORG_LEGAL_EMPLOYER_NAME IS 'N/LE'

HR_EXTRACT_DATE = TO_DATE(CMP_IV_PLAN_ELIG_DATE, 'YYYY/MM/DD')
L_PL_END_DATE   = TO_DATE(CMP_IV_PLAN_END_DATE, 'YYYY/MM/DD')

ELIGIBLE = 'N'
MGR_LVL = 'NO_MGR_LVL'
MGR_LVL_NUM = 0
L_CODE = 'N/A'
L_LEGAL_EMPLOYER = 'N/LE'

ELIG_DATE = TO_DATE(CMP_IV_PLAN_ELIG_DATE, 'YYYY/MM/DD')

l_log = SET_LOG('*** INICIO GB_CMP_ELEGIBILIDAD_R1 ***')

CHANGE_CONTEXTS(EFFECTIVE_DATE = ELIG_DATE)
(
    MGR_LVL = PER_ASG_JOB_MANAGER_LEVEL
    L_CODE = PER_ASG_ATTRIBUTE1

    IF MGR_LVL <> 'NO_MGR_LVL' THEN
    (
        MGR_LVL_NUM = TO_NUM(MGR_LVL)
    )
)

l_log = SET_LOG('Manager Level raw: ' || MGR_LVL)
l_log = SET_LOG('Manager Level num: ' || TO_CHAR(MGR_LVL_NUM))
l_log = SET_LOG('Attribute1 raw: ' || L_CODE)

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

/* Evaluacion de entidad legal para determinar codigo de pais */
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
ELSE IF L_LEGAL_EMPLOYER = 'Barcel, S.A. de C.V.' OR L_LEGAL_EMPLOYER = 'Bimbonet Servicios, S.A.P.I. de C.V.' OR L_LEGAL_EMPLOYER = 'Bimbo, S.A. de C.V.' OR L_LEGAL_EMPLOYER = 'Corporativo Bimbo, S.A. de C.V.' OR L_LEGAL_EMPLOYER = 'Moldes y Exhibidores, S.A. de C.V.' OR L_LEGAL_EMPLOYER = 'Tradicion en Pastelerías, S.A. de C.V.' OR L_LEGAL_EMPLOYER = 'Grupo Bimbo, S.A.B. de C.V.' THEN
    L_KEY_UDT = 'MEX'
ELSE
    L_KEY_UDT = 'DEFAULT'

l_log = SET_LOG('Key pais UDT: ' || L_KEY_UDT)

/* Modificacion de la regla de Elegibilidad */
IF L_KEY_UDT = 'CO' THEN
(
    IF MGR_LVL_NUM >= 6 THEN
    (
        ELIGIBLE = 'Y'
    )
)
ELSE
(
    IF MGR_LVL_NUM >= 2 THEN
    (
        ELIGIBLE = 'Y'
    )
)

l_log = SET_LOG('Resultado elegibilidad: ' || ELIGIBLE)
l_log = SET_LOG('*** FIN GB_CMP_ELEGIBILIDAD_R1 ***')

RETURN ELIGIBLE