/******************************************************************************
* FORMULA NAME      : GB_CMP_APERTURA_R1                                      *
* FORMULA TYPE      : Compensation Default and Override                       *
* DESCRIPTION       : Calcula la apertura del colaborador para Region 4.      *
*                     ESP y PT: sueldo anual dividido entre 365.              *
*                     MOR: sueldo diario dividido entre 30.                   *
* Formula: ((Sueldo - Min) / ((Max - Min) / 30)) + 70                         *
*-----------------------------------------------------------------------------*
* CREATED BY        : IT-GLOBAL                                               *
* CREATION DATE     : 10-Abril-2026                                           *
* LAST UPDATE DATE  : 02-Julio-2026                                           *
*-----------------------------------------------------------------------------*
* Change History:                                                             *
* Author          | Date            | Ver | Comments                          *
*-----------------+-----------------+-----+-----------------------------------*
* IT Global       | 10-Abril-2026   |  1  | Version Inicial                  *
* IT Global       | 23-Junio-2026   |  2  | Divisor por periodicidad: 365    *
*                 |                 |     | para ESP/PT, 30 para MOR         *
* IT Global       | 02-Julio-2026   |  3  | Se acota la fecha efectiva al    *
*                 |                 |     | fin del ciclo del plan           *
* IT Global       | 02-Julio-2026   |  4  | Se mueven los GET_VALUE_SET de   *
*                 |                 |     | Rate ID/Min/Max dentro del       *
*                 |                 |     | CHANGE_CONTEXTS con la fecha     *
*                 |                 |     | acotada, ya que corrían con la   *
*                 |                 |     | fecha de ejecucion real y        *
*                 |                 |     | traian el grade rate vigente hoy *
*                 |                 |     | en vez del vigente al cierre     *
*                 |                 |     | del plan                         *
******************************************************************************/

INPUTS ARE CMP_IV_PLAN_EXTRACTION_DATE (text),
CMP_IV_PLAN_END_DATE (text),
CMP_IVR_ASSIGNMENT_ID (NUMBER_NUMBER)

DEFAULT FOR CMP_IV_PLAN_EXTRACTION_DATE IS '4012/01/01'
DEFAULT FOR CMP_IV_PLAN_END_DATE IS '4712/12/31'
DEFAULT FOR PER_ASG_GRADE_ID IS 123
DEFAULT FOR PER_ASG_PERSON_ID IS 0
DEFAULT FOR CMP_ASSIGNMENT_SALARY_AMOUNT IS 0
DEFAULT FOR PER_ASG_ORG_LEGAL_EMPLOYER_NAME IS 'N/LE'

HR_EXTRACT_DATE = TO_DATE(CMP_IV_PLAN_EXTRACTION_DATE, 'YYYY/MM/DD')
L_PL_END_DATE   = TO_DATE(CMP_IV_PLAN_END_DATE, 'YYYY/MM/DD')
L_PER_ID = PER_ASG_PERSON_ID

l_log = SET_LOG('*** INICIO GB_CMP_APERTURA_R1 ***')
l_log = SET_LOG('Fecha extraccion: ' || TO_CHAR(HR_EXTRACT_DATE))
l_log = SET_LOG('Fecha fin de ciclo: ' || TO_CHAR(L_PL_END_DATE))
l_log = SET_LOG('Person ID: ' || TO_CHAR(L_PER_ID))

L_ASG_ID = CMP_IVR_ASSIGNMENT_ID[1]
l_log = SET_LOG('Assignment ID: ' || TO_CHAR(L_ASG_ID))

/*=== INICIO DIAGNOSTICO NUEVO ===*/
/* Extracción gracias a Oracle Forums  */
L_CTX_ASG = GET_CONTEXT(HR_ASSIGNMENT_ID, -1)
l_log = SET_LOG('Assignment ID segun contexto interno (HR_ASSIGNMENT_ID): ' || TO_CHAR(L_CTX_ASG))
l_log = SET_LOG('Assignment ID segun input CMP_IVR: ' || TO_CHAR(L_ASG_ID))
/*=== FIN DIAGNOSTICO NUEVO ===*/


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


/*============================================================================
  ACOTAR FECHA EFECTIVA AL CIERRE DEL CICLO DEL PLAN
============================================================================*/
CHANGE_CONTEXTS(EFFECTIVE_DATE = HR_EXTRACT_DATE)
(
    L_LEGAL_EMPLOYER = PER_ASG_ORG_LEGAL_EMPLOYER_NAME
    L_GRADE          = PER_ASG_GRADE_ID
    L_SUELDO         = CMP_ASSIGNMENT_SALARY_AMOUNT
    L_PER_ID         = PER_ASG_PERSON_ID
)

l_log = SET_LOG('Legal Employer: ' || L_LEGAL_EMPLOYER)
l_log = SET_LOG('Grade ID: '       || TO_CHAR(L_GRADE))
l_log = SET_LOG('Sueldo: '         || TO_CHAR(L_SUELDO))

IF HR_EXTRACT_DATE > L_PL_END_DATE THEN
(
    L_FECHA_CONTEXTO = L_PL_END_DATE
    l_log = SET_LOG('Extraccion posterior al cierre del ciclo, se acota a fin de ciclo')
)
ELSE
(
    L_FECHA_CONTEXTO = HR_EXTRACT_DATE
)


IF L_KEY_UDT = 'CO' OR L_KEY_UDT = 'EC' OR L_KEY_UDT = 'AR' OR L_KEY_UDT = 'PE' OR L_KEY_UDT = 'PY' THEN
(
    L_SUELDO  = L_SUELDO
)
ELSE
(
    L_SUELDO  = L_SUELDO * 30
)

l_log = SET_LOG('Sueldo normalizado: ' || TO_CHAR(L_SUELDO))

L_DIVISOR = 30

l_log = SET_LOG('Divisor periodicidad: ' || TO_CHAR(L_DIVISOR))
/*============================================================================
  OBTENER MIN Y MAX
============================================================================*/
L_PARAM_PER = '|=PERSON_ID=' || TO_CHAR(L_PER_ID) || '|P_ASSIGNMENT_ID=' || TO_CHAR(L_CTX_ASG) || '|P_EFFECTIVE_DATE=' || TO_CHAR(L_FECHA_CONTEXTO, 'YYYY/MM/DD')
l_log = SET_LOG('Param para Rate ID: ' || L_PARAM_PER)
L_RATE_ID   = TO_NUM(GET_VALUE_SET('GB_CMP_ASG_RATE_ID', L_PARAM_PER))

l_log = SET_LOG('Rate ID: ' || TO_CHAR(L_RATE_ID))

IF L_RATE_ID > 0 THEN
(
    L_PARAM_MIN = '|=P_ASSIGNMENT_RATE=' || TO_CHAR(L_RATE_ID) || '|P_ASSIGNMENT_GRADE=' || TO_CHAR(L_GRADE) || '|P_EFFECTIVE_DATE=' || TO_CHAR(L_FECHA_CONTEXTO, 'YYYY/MM/DD')
    L_PARAM_MAX = '|=P_ASSIGNMENT_GRADE=' || TO_CHAR(L_GRADE)  || '|P_ASSIGNMENT_RATE='  || TO_CHAR(L_RATE_ID) || '|P_EFFECTIVE_DATE=' || TO_CHAR(L_FECHA_CONTEXTO, 'YYYY/MM/DD')
    L_MIN = TO_NUM(GET_VALUE_SET('GB_CMP_RATE_ID_VALUE_MIN', L_PARAM_MIN))
    L_MAX = TO_NUM(GET_VALUE_SET('GB_CMP_RATE_ID_VALUE_MAX', L_PARAM_MAX))
)
ELSE
(
    L_PARAM_GRADE = '|=P_ASSIGNMENT_GRADE=' || TO_CHAR(L_GRADE) || '|P_EFFECTIVE_DATE=' || TO_CHAR(L_FECHA_CONTEXTO, 'YYYY/MM/DD')
    L_MIN = TO_NUM(GET_VALUE_SET('GB_CMP_RATE_VALUE_MIN', L_PARAM_GRADE))
    L_MAX = TO_NUM(GET_VALUE_SET('GB_CMP_RATE_VALUE_MAX', L_PARAM_GRADE))
    l_log = SET_LOG('El Value Set de Grade no tiene Rate ID, se usa el Value Set de Grade directamente')
)

l_log = SET_LOG('Min: ' || TO_CHAR(L_MIN))
l_log = SET_LOG('Max: ' || TO_CHAR(L_MAX))
/*============================================================================
  CALCULO APERTURA
============================================================================*/
IF L_MAX = L_MIN THEN
(
    l_log = SET_LOG('Max igual a Min, retorna 0')
    L_DEFAULT_VALUE = 0
    RETURN L_DEFAULT_VALUE
)

L_VALOR_PUNTO = (L_MAX - L_MIN) / L_DIVISOR
L_APERTURA    = ((L_SUELDO - L_MIN) / L_VALOR_PUNTO) + 70

l_log = SET_LOG('Valor del Punto: ' || TO_CHAR(L_VALOR_PUNTO))
l_log = SET_LOG('*** RESULTADO APERTURA: ' || TO_CHAR(L_APERTURA) || ' ***')

L_DEFAULT_VALUE = L_APERTURA
RETURN L_DEFAULT_VALUE