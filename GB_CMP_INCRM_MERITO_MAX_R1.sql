/******************************************************************************
* FORMULA NAME      : GB_CMP_INCRM_MERITO_MAX_R1                              *
* FORMULA TYPE      : Compensation Default and Override                       *
* DESCRIPTION       : Obtiene el porcentaje maximo de incremento por merito   *
*                     para paises LAC/LAS y Mexico leyendo desde UDT por      *
*                     pais. Para Colombia (L_KEY_UDT = 'CO') la formula       *
*                     calcula la comparacion de Incremento_Legal contra       *
*                     Minimo Rango 1 / Mitad de Incremento Promedio,          *
*                     construye L_CLAVE_CO con sufijo, y lee el codigo de     *
*                     rango (Rango_Maximo) desde GB_CMP_CO_RANGOS_MERITO.     *
*                     Para el resto de paises se lee desde                    *
*                     GB_CMP_LAS_LAC_RANGOS_MERITO por L_CLAVE (sin cambios). *
*                     La resolucion numerica final (RESOLUCION NUMERICA       *
*                     MAXIMO) es unica y compartida para todos los paises,    *
*                     sin hardcode: ambas UDT entregan el mismo tipo de       *
*                     codigo (R1, R1_MIN, R2, R3, R4, PROM, MITAD, NO).       *
*-----------------------------------------------------------------------------*
* CREATED BY        : IT-GLOBAL                                               *
* CREATION DATE     : 07-Abril-2026                                           *
* LAST UPDATE DATE  : 29-Julio-2026                                           *
*-----------------------------------------------------------------------------*
* Change History:                                                             *
* Author          | Date            | Ver | Comments                          *
*-----------------+-----------------+-----+-----------------------------------*
* IT Global       | 15-Abril-2026   |  1  | Version Inicial                   *
* IT Global       | 21-Abril-2026   |  2  | Reestructura dinamica UDT         *
* IT Global       | 27-Mayo-2026    |  3  | Adaptacion R4: key por pais       *
*                 |                 |     | MOR/ESP/PT desde Legal Employer   *
* IT Global       | 29-Mayo-2026    |  4  | Construccion clave en mayusculas  *
*                 |                 |     | para MOR; lectura UDT por idioma  *
* IT Global       | 16-Julio-2026   |  5  | Catalogo real 19 codigos NO       *
*                 |                 |     | PERMANENTE R1. Fix TO_NUM.        *
* IT Global       | 29-Julio-2026   |  6  | Default inline en GET_TABLE_VALUE.*
*                 |                 |     | (REVERTIDO EN V7) Se habia        *
*                 |                 |     | introducido hardcode de texto/    *
*                 |                 |     | numeros para Colombia.            *
* IT Global       | 29-Julio-2026   |  7  | Se elimina el hardcode numerico   *
*                 |                 |     | de Colombia. Se restaura calculo  *
*                 |                 |     | de L_MIN_R1_CO, L_MITAD_PROM_CO   *
*                 |                 |     | e L_INCR_LEGAL (unicamente        *
*                 |                 |     | L_KEY_UDT = 'CO'). Se construye   *
*                 |                 |     | L_CLAVE_CO con sufijo             *
*                 |                 |     | _GE_MINR1/_LT_MINR1 o             *
*                 |                 |     | _GE_MITADPROM/_LT_MITADPROM,      *
*                 |                 |     | mismo patron ya validado en       *
*                 |                 |     | GB_CMP_INCRM_MERITO_RANGO_R1. Se  *
*                 |                 |     | corrige bug de key L_KEY_UDT =    *
*                 |                 |     | 'COL' (nunca coincidia) por 'CO'. *
*                 |                 |     | Se lee Rango_Maximo desde         *
*                 |                 |     | GB_CMP_CO_RANGOS_MERITO usando    *
*                 |                 |     | L_CLAVE_CO como Exact, igual que  *
*                 |                 |     | el resto de paises con L_CLAVE.   *
*                 |                 |     | RESOLUCION NUMERICA MAXIMO vuelve *
*                 |                 |     | a ser un bloque unico compartido, *
*                 |                 |     | sin rama separada para Colombia.  *
*                 |                 |     | Ningun texto ni numero hardcode   *
*                 |                 |     | en formula para Colombia.         *
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
DEFAULT_DATA_VALUE FOR CMP_EXTERNAL_WORKER_DATA_RGE_ASG_ASSIGNMENT_ID IS 0
DEFAULT_DATA_VALUE FOR CMP_EXTERNAL_WORKER_DATA_RGE_ASG_VALUE2 IS 'N/A'
DEFAULT FOR PER_ASG_ATTRIBUTE1 IS 'PERMANENTE'
DEFAULT FOR PER_ASG_ACTION_CODE IS 'N/A'
DEFAULT FOR PER_ASG_EFFECTIVE_START_DATE IS '1900/01/01' (date)
DEFAULT FOR PER_ASG_EFFECTIVE_END_DATE IS '4712/12/31' (date)
DEFAULT FOR PER_ASG_JOB_MANAGER_LEVEL IS 'NA'
DEFAULT FOR PER_ASG_GRADE_ID IS 123
DEFAULT FOR PER_ASG_PERSON_ID IS 0
DEFAULT FOR CMP_ASSIGNMENT_SALARY_AMOUNT IS 0
DEFAULT FOR PER_ASG_ORG_LEGAL_EMPLOYER_NAME IS 'N/LE'
DEFAULT FOR PER_ASG_REL_ORIGINAL_DATE_OF_HIRE IS '1901/01/01' (date)
DEFAULT FOR PER_ASG_ACTION_REASON_CODE IS 'N/A'
DEFAULT_DATA_VALUE FOR PER_HIST_ASG_EFFECTIVE_START_DATE IS '1900/01/01' (date)
DEFAULT_DATA_VALUE FOR PER_HIST_ASG_EFFECTIVE_END_DATE IS '4712/12/31' (date)
DEFAULT_DATA_VALUE FOR PER_HIST_ASG_ASSIGNMENT_ID IS 0

/*============================================================================
  FECHAS BASE
============================================================================*/
HR_EXTRACT_DATE = TO_DATE(CMP_IV_PLAN_EXTRACTION_DATE, 'YYYY/MM/DD')
L_PL_END_DATE   = TO_DATE(CMP_IV_PLAN_END_DATE, 'YYYY/MM/DD')

l_log = SET_LOG('*** INICIO GB_CMP_INCRM_MERITO_MAX_R1 ***')
L_ASG_ID = CMP_IVR_ASSIGNMENT_ID[1]
l_log = SET_LOG('Assignment ID: ' || TO_CHAR(L_ASG_ID))

L_CTX_ASG = GET_CONTEXT(HR_ASSIGNMENT_ID, -1)
l_log = SET_LOG('Assignment ID segun contexto interno (HR_ASSIGNMENT_ID): ' || TO_CHAR(L_CTX_ASG))
l_log = SET_LOG('Assignment ID segun input CMP_IVR: ' || TO_CHAR(L_ASG_ID))

/*============================================================================
  LEGAL EMPLOYER Y KEY UDT POR PAIS
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
ELSE IF 
    L_LEGAL_EMPLOYER = 'Bimbo de Costa Rica, S.A.' 
    OR L_LEGAL_EMPLOYER = 'Centro de Servicios Compartidos Bimbo, S.A.' THEN
    L_KEY_UDT = 'CR'
ELSE IF 
    L_LEGAL_EMPLOYER = 'Barcel De El Salvador, S.A. de C.V.' 
    OR L_LEGAL_EMPLOYER = 'Bimbo de El Salvador, S.A. de C.V.' THEN
    L_KEY_UDT = 'SV'
ELSE IF 
    L_LEGAL_EMPLOYER = 'Bimbo de Centroamerica, S.A.' 
    OR L_LEGAL_EMPLOYER = 'VeCentral, S.A.'  THEN
    L_KEY_UDT = 'GT'
ELSE IF 
    L_LEGAL_EMPLOYER = 'Bimbo de Honduras, S.A. de C.V.' 
    OR L_LEGAL_EMPLOYER = 'Compañía Industrial Lido Pozuelo, S.A. de C.V.' THEN
    L_KEY_UDT = 'HN'
ELSE IF L_LEGAL_EMPLOYER = 'Panificadora Bimbo del Uruguay Sociedad Anonima' THEN
    L_KEY_UDT = 'UY'
ELSE IF 
    L_LEGAL_EMPLOYER = 'Bimbo de Panama, S.A.' 
    OR L_LEGAL_EMPLOYER = 'Nutriamericas S.A.' THEN
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
ELSE IF             
        L_LEGAL_EMPLOYER = 'Barcel, S.A. de C.V.' 
        OR L_LEGAL_EMPLOYER = 'Bimbonet Servicios, S.A.P.I. de C.V.' 
        OR L_LEGAL_EMPLOYER = 'Bimbo, S.A. de C.V.' 
        OR L_LEGAL_EMPLOYER = 'Corporativo Bimbo, S.A. de C.V.' 
        OR L_LEGAL_EMPLOYER = 'Moldes y Exhibidores, S.A. de C.V.' 
        OR L_LEGAL_EMPLOYER = 'Grupo Bimbo, S.A.B. de C.V.'
        OR L_LEGAL_EMPLOYER = 'Tradicion en Pastelerías, S.A. de C.V.' THEN
    L_KEY_UDT = 'MEX'
ELSE
    L_KEY_UDT = 'DEFAULT'

l_log = SET_LOG('Key pais UDT: ' || L_KEY_UDT)

/*============================================================================
  PROMEDIO E INFLACION POR PAIS
============================================================================*/
L_PROM      = TO_NUM(GET_TABLE_VALUE('GB_CMP_LAC_LAS_INCREMENTO_MERITO', 'Incremento_Promedio', L_KEY_UDT, '0'))
L_INFLACION = TO_NUM(GET_TABLE_VALUE('GB_CMP_LAC_LAS_INCREMENTO_MERITO', 'Inflacion_Minima', L_KEY_UDT, '0'))
l_log = SET_LOG('Promedio: '  || TO_CHAR(L_PROM))
l_log = SET_LOG('Inflacion: ' || TO_CHAR(L_INFLACION))

/*============================================================================
  UMBRALES E INCREMENTO LEGAL - Unicamente para Colombia (L_KEY_UDT = 'CO')
============================================================================*/
IF L_KEY_UDT = 'CO' THEN
(
    IF L_PROM > 10 THEN
        L_MIN_R1_CO = L_PROM - 3
    ELSE IF L_PROM >= 5 AND L_PROM <= 10 THEN
        L_MIN_R1_CO = L_PROM * 0.70
    ELSE
        L_MIN_R1_CO = L_PROM - 1.5

    L_MITAD_PROM_CO = L_PROM / 2

    L_INCR_LEGAL_TXT = GET_TABLE_VALUE('GB_CMP_LAC_LAS_INCREMENTO_MERITO', 'Incremento_Legal', L_KEY_UDT, '0')
    L_INCR_LEGAL     = TO_NUM(L_INCR_LEGAL_TXT)
)
ELSE
(
    L_MIN_R1_CO       = 0
    L_MITAD_PROM_CO   = 0
    L_INCR_LEGAL_TXT  = '0'
    L_INCR_LEGAL      = 0
)

l_log = SET_LOG('Minimo Rango 1 CO: ' || TO_CHAR(L_MIN_R1_CO))
l_log = SET_LOG('Mitad Incremento Promedio CO: ' || TO_CHAR(L_MITAD_PROM_CO))
l_log = SET_LOG('Incremento Legal (numerico): ' || TO_CHAR(L_INCR_LEGAL))

/*============================================================================
  EVALUACION
============================================================================*/
L_EVAL_TXT    = 'N/A'
L_EVAL_MAPPED = 'N/A'
L_IDX         = 0

CHANGE_CONTEXTS(EFFECTIVE_DATE = HR_EXTRACT_DATE, COMPENSATION_RECORD_TYPE = 'CMP_MERITO')
(
    L_IDX = CMP_EXTERNAL_WORKER_DATA_RGE_ASG_SEQUENCE_NUMBER.LAST(-1)
    WHILE L_IDX >= 1 LOOP
    (
        L_EXT_VAL = CMP_EXTERNAL_WORKER_DATA_RGE_ASG_VALUE1[L_IDX]
        IF L_EXT_VAL != 'N/A' THEN
        (
            L_EVAL_MAPPED = GET_TABLE_VALUE('GB_CMP_LAC_LAS_CALIFICAC_MERITO', 'Calificacion_Texto', L_EXT_VAL, 'N/A')

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

CHANGE_CONTEXTS(EFFECTIVE_DATE = HR_EXTRACT_DATE)
(
    L_LEGAL_EMPLOYER = PER_ASG_ORG_LEGAL_EMPLOYER_NAME
    L_GRADE          = PER_ASG_GRADE_ID
    L_SUELDO         = CMP_ASSIGNMENT_SALARY_AMOUNT
    L_PER_ID         = PER_ASG_PERSON_ID
)
/*
l_log = SET_LOG('Legal Employer: ' || L_LEGAL_EMPLOYER)
l_log = SET_LOG('Grade ID: '       || TO_CHAR(L_GRADE))
l_log = SET_LOG('Sueldo (crudo, primera lectura): ' || TO_CHAR(L_SUELDO))
*/
/*============================================================================
  DATOS DEL ASSIGNMENT
============================================================================*/
CHANGE_CONTEXTS(EFFECTIVE_DATE = HR_EXTRACT_DATE)
(
    L_TIPO_CONTRATO    = PER_ASG_ATTRIBUTE1
    L_ACTION           = PER_ASG_ACTION_CODE
    L_HIRE_DATE        = PER_ASG_EFFECTIVE_START_DATE
    L_GRADE            = PER_ASG_GRADE_ID
    L_SUELDO           = CMP_ASSIGNMENT_SALARY_AMOUNT
    L_PER_ID           = PER_ASG_PERSON_ID
    MGR_LVL            = PER_ASG_JOB_MANAGER_LEVEL
    ASSIGN_START_DATE  = PER_ASG_EFFECTIVE_START_DATE
    ASSIGN_END_DATE    = PER_ASG_EFFECTIVE_END_DATE
)
/*
l_log = SET_LOG('Tipo contrato: '        || L_TIPO_CONTRATO)
l_log = SET_LOG('Action code: '          || L_ACTION)
l_log = SET_LOG('Hire Date: '            || TO_CHAR(L_HIRE_DATE, 'YYYY/MM/DD'))
l_log = SET_LOG('Grade ID: '             || TO_CHAR(L_GRADE))
l_log = SET_LOG('Sueldo (crudo, segunda lectura): ' || TO_CHAR(L_SUELDO))
l_log = SET_LOG('Manager Level Actual: ' || MGR_LVL)
*/

IF L_KEY_UDT = 'CO' OR L_KEY_UDT = 'EC' OR L_KEY_UDT = 'AR' OR L_KEY_UDT = 'PE' OR L_KEY_UDT = 'PY' THEN
(
    L_SUELDO  = L_SUELDO
)
ELSE
(
    L_SUELDO  = L_SUELDO * 30.4168
)

L_DIVISOR = 30

l_log = SET_LOG('Sueldo ajustado (final): ' || TO_CHAR(L_SUELDO))
l_log = SET_LOG('Divisor periodicidad: '     || TO_CHAR(L_DIVISOR))

/*============================================================================
  CALCULO APERTURA
============================================================================*/
L_PARAM_PER = '|=PERSON_ID=' || TO_CHAR(L_PER_ID) || '|P_ASSIGNMENT_ID=' || TO_CHAR(L_CTX_ASG) || '|P_EFFECTIVE_DATE=' || TO_CHAR(L_FECHA_CONTEXTO, 'YYYY/MM/DD')
L_RATE_ID = TO_NUM(GET_VALUE_SET('GB_CMP_ASG_RATE_ID', L_PARAM_PER))
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
)

l_log = SET_LOG('Min plan: ' || TO_CHAR(L_MIN))
l_log = SET_LOG('Max plan: ' || TO_CHAR(L_MAX))

IF L_MAX = L_MIN THEN
    L_APERTURA = 0
ELSE
(
    L_VALOR_PUNTO = (L_MAX - L_MIN) / L_DIVISOR
    L_APERTURA    = ((L_SUELDO - L_MIN) / L_VALOR_PUNTO) + 70
)
l_log = SET_LOG('Apertura calculada: ' || TO_CHAR(L_APERTURA))
l_log = SET_LOG('Valor del punto : '  || TO_CHAR(L_VALOR_PUNTO))

/*============================================================================
  DETECCION DE PROMOCION POR RETROFIT
============================================================================*/
PROMOTION_START_DATE = ADD_MONTHS(L_PL_END_DATE, -5)
PROMOTION_END_DATE   = HR_EXTRACT_DATE
/*
l_log = SET_LOG('Promotion Start Date: ' || TO_CHAR(PROMOTION_START_DATE, 'YYYY/MM/DD'))
l_log = SET_LOG('Promotion End Date: '   || TO_CHAR(PROMOTION_END_DATE,   'YYYY/MM/DD'))
*/
LEVEL1       = 'NA'
PRIOR_LEVEL  = 'NA'
LEVEL_CHANGE = 'N'
PRO          = 'N'
L_COUNT      = 0

IF ASSIGN_START_DATE >= PROMOTION_START_DATE AND ASSIGN_START_DATE <= PROMOTION_END_DATE THEN
(
    WHILE L_COUNT <= 10 LOOP
    (
        L_COUNT = L_COUNT + 1
        PRIOR_ASSIGN_START_DATE = ADD_DAYS(ASSIGN_START_DATE, -1)

        IF ASSIGN_END_DATE > PROMOTION_START_DATE THEN
        (
            CHANGE_CONTEXTS(EFFECTIVE_DATE = PRIOR_ASSIGN_START_DATE)
            (
                PRIOR_ASSIGN_START_DATE = PER_ASG_EFFECTIVE_START_DATE
                PRIOR_ASSIGN_END_DATE   = PER_ASG_EFFECTIVE_END_DATE
                PRIOR_LEVEL             = PER_ASG_JOB_MANAGER_LEVEL

                IF PRIOR_LEVEL != 'NA' AND PRIOR_LEVEL = MGR_LVL THEN
                (
                    ASSIGN_START_DATE = PRIOR_ASSIGN_START_DATE
                )
                ELSE
                (
                    IF PRIOR_ASSIGN_END_DATE < PROMOTION_START_DATE THEN
                    (
                        ASSIGN_START_DATE = PRIOR_ASSIGN_START_DATE
                    )
                    ELSE
                    (
                        LEVEL1  = PRIOR_LEVEL
                        L_COUNT = 11
                    )
                )
            )
        )
    )
)

IF LEVEL1 != 'NA' AND MGR_LVL != 'NA' THEN
(
    IF TO_NUM(MGR_LVL) > TO_NUM(LEVEL1) THEN
        LEVEL_CHANGE = 'Y'
)

IF LEVEL_CHANGE = 'Y' THEN
    PRO = 'PRO'
/*
l_log = SET_LOG('Level previo (LEVEL1): ' || LEVEL1)
l_log = SET_LOG('Level change: '          || LEVEL_CHANGE)
l_log = SET_LOG('PRO flag: '              || PRO)
*/

/*============================================================================
  DETECCION DE TRANSFERENCIA INTERCOMPANIA
  Misma logica validada en GB_CMP_NEW_HIRE_RETROFIT v11.
============================================================================*/
L_ES_INTERCOMPANIA = 'N'

IF PER_ASG_REL_ORIGINAL_DATE_OF_HIRE >= PROMOTION_START_DATE THEN
(
    L_DIA_ANT_HIRE = ADD_DAYS(L_HIRE_DATE, -1)
    L_ASG_ANT = 0
    L_TOTAL_HIST = PER_HIST_ASG_EFFECTIVE_START_DATE.LAST(-1)
    L_H = L_TOTAL_HIST
    WHILE L_H >= 1 LOOP
    (
        L_H_INICIO = PER_HIST_ASG_EFFECTIVE_START_DATE[L_H]
        L_H_FIN = PER_HIST_ASG_EFFECTIVE_END_DATE[L_H]
        L_H_ASG = PER_HIST_ASG_ASSIGNMENT_ID[L_H]

        IF L_H_ASG <> L_CTX_ASG AND L_DIA_ANT_HIRE >= L_H_INICIO AND L_DIA_ANT_HIRE <= L_H_FIN AND L_ASG_ANT = 0 THEN
        (
            L_ASG_ANT = L_H_ASG
            L_H = 0
        )
        ELSE
            L_H = L_H - 1
    )

    IF L_ASG_ANT <> 0 THEN
    (
        L_RC = 'N/A'
        CHANGE_CONTEXTS(HR_ASSIGNMENT_ID = L_ASG_ANT, EFFECTIVE_DATE = L_HIRE_DATE)
        (
            L_RC = PER_ASG_ACTION_REASON_CODE
        )
        l_log = SET_LOG('Reason code assignment anterior: ' || L_RC)

         IF L_RC = '28'
        OR L_RC = 'C28'
        OR L_RC = '00'
        OR L_RC = '0004'
        OR L_RC = '0032'
        OR L_RC = 'U00'
        OR L_RC = '115'
        OR L_RC = '64'
        OR L_RC = '114'
        THEN
            L_ES_INTERCOMPANIA = 'Y'
    )
)

l_log = SET_LOG('Es intercompania: ' || L_ES_INTERCOMPANIA)

/*============================================================================
  VALIDACION DE CONTRATO NO PERMANENTE (catalogo real R1)
============================================================================*/
IF L_TIPO_CONTRATO = 'AR25' OR
   L_TIPO_CONTRATO = 'FA12' OR
   L_TIPO_CONTRATO = 'FA14' OR
   L_TIPO_CONTRATO = 'FA22' OR
   L_TIPO_CONTRATO = 'CL22' OR
   L_TIPO_CONTRATO = 'CR2'  OR
   L_TIPO_CONTRATO = '00020' OR
   L_TIPO_CONTRATO = '00022' OR
   L_TIPO_CONTRATO = '00023' OR
   L_TIPO_CONTRATO = 'MEX1' OR
   L_TIPO_CONTRATO = 'MEX3' OR
   L_TIPO_CONTRATO = 'MEX5' OR
   L_TIPO_CONTRATO = 'PY1'  OR
   L_TIPO_CONTRATO = 'PE03' OR
   L_TIPO_CONTRATO = 'PE05' OR
   L_TIPO_CONTRATO = 'UY02' OR
   L_TIPO_CONTRATO = 'UY04' OR
   L_TIPO_CONTRATO = 'UY05' OR
   L_TIPO_CONTRATO = 'UY06' THEN
    L_ES_NO_PERM = 'Y'
ELSE
    L_ES_NO_PERM = 'N'
/*
l_log = SET_LOG('Es No Permanente: ' || L_ES_NO_PERM)
*/
/*============================================================================
  CONDICION
============================================================================*/
L_CINCO_MESES = ADD_MONTHS(L_PL_END_DATE, -5)

IF PRO = 'PRO' THEN
    L_CONDICION = 'Promotion'
ELSE IF L_ES_NO_PERM = 'Y' THEN
    L_CONDICION = 'NonPerm'
ELSE IF PER_ASG_REL_ORIGINAL_DATE_OF_HIRE >= L_CINCO_MESES 
AND L_ES_INTERCOMPANIA = 'N' THEN
    L_CONDICION = 'NewHire'
ELSE
    L_CONDICION = 'None'
l_log = SET_LOG('Condicion: ' || L_CONDICION)

/*============================================================================
  CONSTRUCCION DE CLAVE UDT (SIN CAMBIOS) - usada por GET_TABLE_VALUE sobre
  GB_CMP_LAS_LAC_RANGOS_MERITO para todo pais con L_KEY_UDT != 'CO'
============================================================================*/
IF L_CONDICION = 'Promotion' AND (L_EVAL_TXT = 'Sobresaliente' OR L_EVAL_TXT = 'Supera' OR L_EVAL_TXT = 'Cumple con lo esperado'
OR L_EVAL_TXT = 'N/A') THEN
    L_CLAVE = 'Promotion'
ELSE IF L_CONDICION = 'NonPerm' THEN
    L_CLAVE = 'NonPerm'
ELSE IF L_CONDICION = 'NewHire' THEN
    L_CLAVE = 'NewHire'
ELSE IF L_EVAL_TXT = 'N/A' THEN
    L_CLAVE = 'SinEval'
ELSE IF L_EVAL_TXT = 'Exit' THEN
    L_CLAVE = 'Exit'
ELSE IF L_EVAL_TXT = 'Salida' THEN
    L_CLAVE = 'Salida'
ELSE IF L_APERTURA <= 100 THEN
    L_CLAVE = L_EVAL_TXT || '_LT100'
ELSE
    L_CLAVE = L_EVAL_TXT || '_GE100'

l_log = SET_LOG('Clave UDT: ' || L_CLAVE)

/*============================================================================
  CLAVE COLOMBIA - calcula la comparacion contra Incremento_Legal y
  construye la key con sufijo. Solo se calcula si L_KEY_UDT = 'CO'.
  Mismo patron ya validado en GB_CMP_INCRM_MERITO_RANGO_R1.
============================================================================*/
IF L_KEY_UDT = 'CO' THEN
(
    IF L_CONDICION = 'Promotion' AND L_EVAL_TXT = 'Sobresaliente' THEN
        L_CLAVE_CO = 'Sobresaliente_Prom'
    ELSE IF L_CONDICION = 'NonPerm' THEN
    (
        IF L_INCR_LEGAL > L_MIN_R1_CO THEN
            L_CLAVE_CO = 'NonPerm_GE_MINR1'
        ELSE
            L_CLAVE_CO = 'NonPerm_LT_MINR1'
    )
    ELSE IF L_CONDICION = 'NewHire' THEN
    (
        IF L_INCR_LEGAL > L_MIN_R1_CO THEN
            L_CLAVE_CO = 'NewHire_GE_MINR1'
        ELSE
            L_CLAVE_CO = 'NewHire_LT_MINR1'
    )
    ELSE IF L_EVAL_TXT = 'N/A' THEN
    (
        IF L_INCR_LEGAL > L_MIN_R1_CO THEN
            L_CLAVE_CO = 'SinEval_GE_MINR1'
        ELSE
            L_CLAVE_CO = 'SinEval_LT_MINR1'
    )
    ELSE IF L_EVAL_TXT = 'Exit' OR L_EVAL_TXT = 'Salida' THEN
        L_CLAVE_CO = 'Salida'
    ELSE IF L_EVAL_TXT = 'Necesita mejora' OR L_EVAL_TXT = 'Por debajo de lo esperado' THEN
    (
        IF L_INCR_LEGAL > L_MITAD_PROM_CO THEN
            L_CLAVE_CO = L_EVAL_TXT || '_GE_MITADPROM'
        ELSE
            L_CLAVE_CO = L_EVAL_TXT || '_LT_MITADPROM'
    )
    ELSE IF L_EVAL_TXT = 'Sobresaliente' AND L_APERTURA < 100 THEN
        L_CLAVE_CO = 'Sobresaliente_LT100'
    ELSE IF L_EVAL_TXT = 'Sobresaliente' AND L_APERTURA >= 100 THEN
    (
        IF L_INCR_LEGAL > L_MIN_R1_CO THEN
            L_CLAVE_CO = 'Sobresaliente_GE100_GE_MINR1'
        ELSE
            L_CLAVE_CO = 'Sobresaliente_GE100_LT_MINR1'
    )
    ELSE IF L_EVAL_TXT = 'Cumple con lo esperado' AND L_APERTURA < 100 THEN
    (
        IF L_INCR_LEGAL > L_MIN_R1_CO THEN
            L_CLAVE_CO = 'Cumple con lo esperado_LT100_GE_MINR1'
        ELSE
            L_CLAVE_CO = 'Cumple con lo esperado_LT100_LT_MINR1'
    )
    ELSE IF L_EVAL_TXT = 'Cumple con lo esperado' AND L_APERTURA >= 100 THEN
    (
        IF L_INCR_LEGAL > L_MIN_R1_CO THEN
            L_CLAVE_CO = 'Cumple con lo esperado_GE100_GE_MINR1'
        ELSE
            L_CLAVE_CO = 'Cumple con lo esperado_GE100_LT_MINR1'
    )
    ELSE IF L_EVAL_TXT = 'Supera' AND L_APERTURA < 100 THEN
        L_CLAVE_CO = 'Supera_LT100'
    ELSE IF L_EVAL_TXT = 'Supera' AND L_APERTURA >= 100 THEN
        L_CLAVE_CO = 'Supera_GE100'
    ELSE
        L_CLAVE_CO = 'SinClasificar'
)
ELSE
    L_CLAVE_CO = 'N/A'

l_log = SET_LOG('Clave switch CO: ' || L_CLAVE_CO)

/*============================================================================
  LECTURA UDT POR IDIOMA / PAIS
  Colombia (L_KEY_UDT = 'CO'): GB_CMP_CO_RANGOS_MERITO por L_CLAVE_CO
  Resto de paises: GB_CMP_LAS_LAC_RANGOS_MERITO por L_CLAVE
============================================================================*/
IF L_KEY_UDT = 'CO' THEN
(
    L_RANGO_MAX  = GET_TABLE_VALUE('GB_CMP_CO_RANGOS_MERITO', 'Rango_Maximo', L_CLAVE_CO, 'NO')
    L_APLICA_INF = GET_TABLE_VALUE('GB_CMP_CO_RANGOS_MERITO', 'Aplica_Inflacion', L_CLAVE_CO, 'N')
)
ELSE
(
    L_RANGO_MAX  = GET_TABLE_VALUE('GB_CMP_LAS_LAC_RANGOS_MERITO', 'Rango_Maximo', L_CLAVE, 'NO')
    L_APLICA_INF = GET_TABLE_VALUE('GB_CMP_LAS_LAC_RANGOS_MERITO', 'Aplica_Inflacion', L_CLAVE, 'N')
)
l_log = SET_LOG('Rango Max: '        || L_RANGO_MAX)
l_log = SET_LOG('Aplica Inflacion: ' || L_APLICA_INF)

/*============================================================================
  CALCULO VALORES NUMERICOS POR RANGO (SIN CAMBIOS)
============================================================================*/
IF L_PROM > 10 THEN
(
    L_VAL_R1_MIN = L_PROM - 3
    L_VAL_R2_MIN = L_PROM - 1.5
    L_VAL_R3_MIN = L_PROM
    L_VAL_R4_MIN = L_PROM + 1.5
    L_VAL_R1 = L_PROM - 1.5
    L_VAL_R2 = L_PROM
    L_VAL_R3 = L_PROM + 1.5
    L_VAL_R4 = L_PROM + 3
)
ELSE IF L_PROM >= 5 AND L_PROM <= 10 THEN
(
    L_VAL_R1_MIN = L_PROM * 0.70
    L_VAL_R2_MIN = L_PROM * 0.85
    L_VAL_R3_MIN = L_PROM
    L_VAL_R4_MIN = L_PROM * 1.15
    L_VAL_R1 = L_PROM * 0.85
    L_VAL_R2 = L_PROM
    L_VAL_R3 = L_PROM * 1.15
    L_VAL_R4 = L_PROM * 1.30
)
ELSE
(
    L_VAL_R1_MIN = L_PROM - 1.5
    L_VAL_R2_MIN = L_PROM - 0.75
    L_VAL_R3_MIN = L_PROM
    L_VAL_R4_MIN = L_PROM + 0.75
    L_VAL_R1 = L_PROM - 0.75
    L_VAL_R2 = L_PROM
    L_VAL_R3 = L_PROM + 0.75
    L_VAL_R4 = L_PROM + 1.5
)

l_log = SET_LOG('Val R1: ' || TO_CHAR(L_VAL_R1))
l_log = SET_LOG('Val R2: ' || TO_CHAR(L_VAL_R2))
l_log = SET_LOG('Val R3: ' || TO_CHAR(L_VAL_R3))
l_log = SET_LOG('Val R4: ' || TO_CHAR(L_VAL_R4))


/*============================================================================
  RESOLUCION NUMERICA MAXIMO
  Unificada para todos los paises, incluida Colombia. L_RANGO_MAX ya viene
  resuelto por pais desde la UDT correspondiente (L_CLAVE_CO para CO,
  L_CLAVE para el resto), ambas entregan el mismo tipo de codigo
  (R1, R1_MIN, R2, R3, R4, PROM, MITAD, NO).
============================================================================*/
IF L_RANGO_MAX = 'NO' THEN
    L_DEFAULT_MAX = 0
ELSE IF L_RANGO_MAX = 'R0_MIN' THEN
    L_DEFAULT_MAX = 0
ELSE IF L_RANGO_MAX = 'R0_MAX' THEN
    L_DEFAULT_MAX = L_VAL_R1_MIN
ELSE IF L_RANGO_MAX = 'R1_MIN' THEN
    L_DEFAULT_MAX = L_VAL_R1_MIN
ELSE IF L_RANGO_MAX = 'R1_MAX' OR L_RANGO_MAX = 'R1' THEN
    L_DEFAULT_MAX = L_VAL_R1
ELSE IF L_RANGO_MAX = 'R2_MIN' THEN
    L_DEFAULT_MAX = L_VAL_R2_MIN
ELSE IF L_RANGO_MAX = 'R2_MAX' OR L_RANGO_MAX = 'R2' THEN
    L_DEFAULT_MAX = L_VAL_R2
ELSE IF L_RANGO_MAX = 'R3_MIN' THEN
    L_DEFAULT_MAX = L_VAL_R3_MIN
ELSE IF L_RANGO_MAX = 'R3_MAX' OR L_RANGO_MAX = 'R3' THEN
    L_DEFAULT_MAX = L_VAL_R3
ELSE IF L_RANGO_MAX = 'R4_MIN' THEN
    L_DEFAULT_MAX = L_VAL_R4_MIN
ELSE IF L_RANGO_MAX = 'R4_MAX' OR L_RANGO_MAX = 'R4' THEN
    L_DEFAULT_MAX = L_VAL_R4
ELSE IF L_RANGO_MAX = 'PROM' THEN
    L_DEFAULT_MAX = L_PROM
ELSE IF L_RANGO_MAX = 'HALF_PROM' THEN
    L_DEFAULT_MAX = L_PROM / 2
ELSE IF L_RANGO_MAX = 'MITAD' THEN
    L_DEFAULT_MAX = L_PROM / 2
ELSE IF L_RANGO_MAX = 'INC_LG' THEN
    L_DEFAULT_MAX = L_INCR_LEGAL
ELSE
    L_DEFAULT_MAX = 0
/*============================================================================
  APLICAR INFLACION MINIMA (SIN CAMBIOS)
============================================================================*/
IF L_APLICA_INF = 'S' AND L_DEFAULT_MAX < L_INFLACION THEN
    L_DEFAULT_MAX = L_INFLACION

l_log = SET_LOG('*** RESULTADO MAX: ' || TO_CHAR(L_DEFAULT_MAX) || ' ***')
RETURN L_DEFAULT_MAX