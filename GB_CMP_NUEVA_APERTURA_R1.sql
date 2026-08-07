/*****************************************************************************
FORMULA NAME: GB_CMP_NUEVA_APERTURA_R1
CREATED_BY : IT-GLOBAL
CREATION_DATE : 23 de Junio del 2026
LAST_UPDATE_DATE : 23 de Junio del 2026
FORMULA TYPE : Compensation Default and Override
DESCRIPTION : Calcula la Nueva Apertura del colaborador para Region 1 (LAC)
              considerando el Nuevo Minimo (Minimo actual + Incremento Plan
              Salarial LAC/LAS) y el Nuevo Sueldo Diario asignado en la hoja
              de trabajo.
              Formula: ((Nuevo Sueldo - Nuevo Minimo) / Nuevo Valor del Punto) + 70
              Sueldo diario, divisor fijo 30.
-----------------------------------------------------------------------------
Change History:
Author          | Date            | Ver | Comments
-----------------+-----------------+-----+-----------------------------------
IT Global       | 23-Junio-2026   |  1  | Version Inicial
IT Global       | 23-Junio-2026   |  2  | Uso de L_CTX_ASG via GET_CONTEXT
                 |                 |     | (HR_ASSIGNMENT_ID,-1) en params de
                 |                 |     | Value Set. Divisor fijo 30 (R1 =
                 |                 |     | sueldo diario).
IT Global       | 23-Junio-2026   |  3  | Mapeo de pais via PER_ASG_LEGISLATION_CODE
                 |                 |     | contra UDT GB_CMP_LAC_LAS_INC_PLAN_SALARIAL.
                 |                 |     | PENDIENTE VALIDAR: codigos exactos que
                 |                 |     | regresa el DBI vs claves de la UDT.
*****************************************************************************/
INPUTS ARE CMP_IV_PLAN_EXTRACTION_DATE (text),
CMP_IV_PLAN_END_DATE (text),
CMP_IVR_ASSIGNMENT_ID (NUMBER_NUMBER)

DEFAULT FOR CMP_IV_PLAN_EXTRACTION_DATE IS '4012/01/01'
DEFAULT FOR PER_ASG_GRADE_ID IS 123
DEFAULT FOR CMP_IV_PLAN_END_DATE IS '4712/12/31'
DEFAULT FOR PER_ASG_PERSON_ID IS 0
DEFAULT FOR CMP_ASSIGNMENT_SALARY_AMOUNT IS 0
DEFAULT FOR PER_ASG_LEGISLATION_CODE IS 'N/A'
DEFAULT FOR PER_ASG_ORG_LEGAL_EMPLOYER_NAME IS 'N/LE'

HR_EXTRACT_DATE = TO_DATE(CMP_IV_PLAN_EXTRACTION_DATE, 'YYYY/MM/DD')
L_PL_END_DATE   = TO_DATE(CMP_IV_PLAN_END_DATE, 'YYYY/MM/DD')
L_PER_ID = PER_ASG_PERSON_ID


l_log = SET_LOG('*** INICIO GB_CMP_NUEVA_APERTURA_R1 ***')


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

/*============================================================================
  GRADE, PERSON, LEGISLATION, NUEVO SUELDO Y CONTEXTO REAL DE ASSIGNMENT
============================================================================*/

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
ELSE IF L_LEGAL_EMPLOYER = 'Barcel  de El Salvador, S.A. de C.V.' OR L_LEGAL_EMPLOYER =  'Barcel De El Salvador, S.A. de C.V.' OR L_LEGAL_EMPLOYER = 'Bimbo de El Salvador, S.A. de C.V.' THEN
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
    L_SUELDO  = L_SUELDO * 30.4168
)

l_log = SET_LOG('Sueldo normalizado: ' || TO_CHAR(L_SUELDO))


/*============================================================================
  OBTENER MIN Y MAX ACTUALES (Rate/Grade) - PARAMS CON L_CTX_ASG
============================================================================*/
L_PARAM_PER = '|=PERSON_ID=' || TO_CHAR(L_PER_ID) || '|P_ASSIGNMENT_ID=' || TO_CHAR(L_CTX_ASG) || '|P_EFFECTIVE_DATE=' || TO_CHAR(HR_EXTRACT_DATE, 'YYYY/MM/DD')
L_RATE_ID   = TO_NUM(GET_VALUE_SET('GB_CMP_ASG_RATE_ID', L_PARAM_PER))
l_log = SET_LOG('Rate ID: ' || TO_CHAR(L_RATE_ID))

IF L_RATE_ID > 0 THEN
(
    L_PARAM_MIN = '|=P_ASSIGNMENT_RATE=' || TO_CHAR(L_RATE_ID) || '|P_ASSIGNMENT_GRADE=' || TO_CHAR(L_GRADE) || '|P_ASSIGNMENT_ID=' || TO_CHAR(L_CTX_ASG) || '|P_EFFECTIVE_DATE=' || TO_CHAR(HR_EXTRACT_DATE, 'YYYY/MM/DD')
    L_PARAM_MAX = '|=P_ASSIGNMENT_GRADE=' || TO_CHAR(L_GRADE)  || '|P_ASSIGNMENT_RATE='  || TO_CHAR(L_RATE_ID) || '|P_ASSIGNMENT_ID=' || TO_CHAR(L_CTX_ASG) || '|P_EFFECTIVE_DATE=' || TO_CHAR(HR_EXTRACT_DATE, 'YYYY/MM/DD')
    L_MIN = TO_NUM(GET_VALUE_SET('GB_CMP_RATE_ID_VALUE_MIN', L_PARAM_MIN))
    L_MAX = TO_NUM(GET_VALUE_SET('GB_CMP_RATE_ID_VALUE_MAX', L_PARAM_MAX))
)
ELSE
(
    L_PARAM_GRADE = '|=P_ASSIGNMENT_GRADE=' || TO_CHAR(L_GRADE) || '|P_ASSIGNMENT_ID=' || TO_CHAR(L_CTX_ASG) || '|P_EFFECTIVE_DATE=' || TO_CHAR(HR_EXTRACT_DATE, 'YYYY/MM/DD')
    L_MIN = TO_NUM(GET_VALUE_SET('GB_CMP_RATE_VALUE_MIN', L_PARAM_GRADE))
    L_MAX = TO_NUM(GET_VALUE_SET('GB_CMP_RATE_VALUE_MAX', L_PARAM_GRADE))
)

l_log = SET_LOG('Min actual: ' || TO_CHAR(L_MIN))
l_log = SET_LOG('Max actual: ' || TO_CHAR(L_MAX))

IF L_MAX = L_MIN THEN
(
    l_log = SET_LOG('Max igual a Min, retorna 0')
    L_DEFAULT_VALUE = 0
    RETURN L_DEFAULT_VALUE
)

/*============================================================================
  INCREMENTO PLAN SALARIAL LAC/LAS (UDT) Y NUEVO MINIMO
============================================================================*/
L_INCR_PLAN = TO_NUM(GET_TABLE_VALUE('GB_CMP_LAC_LAS_INC_PLAN_SALARIAL', 'Valor_Inc_Plan_Salarial', L_KEY_UDT))

L_INCR_PLAN = L_INCR_PLAN / 100

l_log = SET_LOG('Incremento Plan Salarial (%): ' || TO_CHAR(L_INCR_PLAN))

L_NUEVO_MIN = L_MIN + (L_MIN * L_INCR_PLAN)

L_NUEVO_MAX = L_MAX + (L_MAX * L_INCR_PLAN)

l_log = SET_LOG('Nuevo Minimo: ' || TO_CHAR(L_NUEVO_MIN))

/*============================================================================
  NUEVO VALOR DEL PUNTO Y NUEVA APERTURA
============================================================================*/
L_DIVISOR = 30
l_log = SET_LOG('Divisor periodicidad: ' || TO_CHAR(L_DIVISOR))

L_NUEVO_VALOR_PUNTO = (L_NUEVO_MAX - L_NUEVO_MIN) / L_DIVISOR

IF L_NUEVO_VALOR_PUNTO = 0 THEN
(
    l_log = SET_LOG('Nuevo Valor del Punto es 0, retorna 0')
    L_DEFAULT_VALUE = 0
    RETURN L_DEFAULT_VALUE
)

L_NUEVA_APERTURA = ((L_SUELDO - L_NUEVO_MIN) / L_NUEVO_VALOR_PUNTO) + 70

l_log = SET_LOG('Nuevo Valor del Punto: ' || TO_CHAR(L_NUEVO_VALOR_PUNTO))
l_log = SET_LOG('*** RESULTADO NUEVA APERTURA: ' || TO_CHAR(L_NUEVA_APERTURA) || ' ***')

L_DEFAULT_VALUE = L_NUEVA_APERTURA
RETURN L_DEFAULT_VALUE