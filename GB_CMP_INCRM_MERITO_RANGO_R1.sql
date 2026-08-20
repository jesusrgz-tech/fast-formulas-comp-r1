/******************************************************************************
* FORMULA NAME      : GB_CMP_INCRM_MERITO_RANGO_R1                            *
* CREATED_BY        : IT-GLOBAL                                               *
* CREATION_DATE     : 07 de Abril del 2026                                    *
* LAST_UPDATE_DATE   : 29 de Julio del 2026                                   *
* FORMULA TYPE       : Compensation Default and Override                     *
* DESCRIPTION        : Obtiene el texto del rango de incremento por merito    *
*                      para paises LAC/LAS y Mexico. Key por pais derivada    *
*                      del Legal Employer. Para el resto de paises el texto   *
*                      de rango se lee desde UDT GB_CMP_LAS_LAC_RANGOS_MERITO *
*                      por L_CLAVE (sin cambios). Para Colombia (L_KEY_UDT =  *
*                      'CO') la formula CALCULA la comparacion de             *
*                      Incremento_Legal contra Minimo Rango 1 / Mitad de      *
*                      Incremento Promedio, y construye L_CLAVE_CO con un     *
*                      sufijo (_GE_MINR1/_LT_MINR1 o _GE_MITADPROM/           *
*                      _LT_MITADPROM) que refleja el resultado. El texto no   *
*                      se hardcodea: se lee via GET_TABLE_VALUE contra        *
*                      GB_CMP_CO_RANGOS_MERITO usando L_CLAVE_CO como Exact.  *
*                      Funcionales pueblan las filas de esa UDT con el texto  *
*                      correspondiente a cada key ya calculada.               *
*------------------------------------------------------------------------------*
* Change History:                                                             *
* Author          | Date            | Ver | Comments                          *
*-----------------+-----------------+-----+-----------------------------------*
* IT Global       | 15-Abril-2026   |  1  | Version Inicial                  *
* IT Global       | 21-Abril-2026   |  2  | Reestructura dinamica UDT        *
* IT Global       | 14-Mayo-2026    |  3  | Replica logica retrofit promotion*
* IT Global       | 27-Mayo-2026    |  4  | Adaptacion R4: key por pais      *
* IT Global       | 28-Mayo-2026    |  5  | Correccion UDT rangos por idioma *
* IT Global       | 22-Junio-2026   |  6  | Sin external data mapea a        *
*                 |                 |     | Exit/Salida segun pais           *
* IT Global       | 07-Julio-2026   |  7  | Fix fecha acotada al fin de ciclo*
*                 |                 |     | en CHANGE_CONTEXTS de apertura;  *
*                 |                 |     | agregado P_EFFECTIVE_DATE a los  *
*                 |                 |     | GET_VALUE_SET de Min/Max;        *
*                 |                 |     | Mexico ahora convierte sueldo    *
*                 |                 |     | diario x30 y usa divisor 30      *
*                 |                 |     | (antes usaba 365 de forma fija)  *
* IT Global       | 16-Julio-2026   |  8  | Reemplazo de comparacion         *
*                 |                 |     | L_TIPO_CONTRATO = '2' por        *
*                 |                 |     | validacion contra catalogo real  *
*                 |                 |     | de 19 codigos NO PERMANENTE R1   *
* IT Global       | 28-Julio-2026   |  9  | (REVERTIDO EN V12) Se habia      *
*                 |                 |     | retirado por completo la lectura *
*                 |                 |     | UDT del texto de rango.          *
* IT Global       | 29-Julio-2026   | 10  | (REVERTIDO) DEFAULT_DATA_VALUE   *
*                 |                 |     | FOR GET_TABLE_VALUE no es        *
*                 |                 |     | sintaxis valida.                 *
* IT Global       | 29-Julio-2026   | 11  | Correccion sintaxis: default     *
*                 |                 |     | value como 4to parametro inline. *
* IT Global       | 29-Julio-2026   | 12  | (REVERTIDO EN V13) Hardcode de    *
*                 |                 |     | texto en formula para Colombia.  *
* IT Global       | 29-Julio-2026   | 13  | (REVERTIDO EN V14) Se asumio que  *
*                 |                 |     | Colombia podia usar L_CLAVE       *
*                 |                 |     | identico al resto de paises, sin *
*                 |                 |     | calcular la comparacion de        *
*                 |                 |     | Incremento_Legal en formula.      *
*                 |                 |     | Incorrecto: la comparacion SI     *
*                 |                 |     | debe calcularse en formula, solo  *
*                 |                 |     | el TEXTO resultante se saca de    *
*                 |                 |     | hardcode.                         *
* IT Global       | 29-Julio-2026   | 14  | Se restaura calculo de L_MIN_R1,  *
*                 |                 |     | L_MITAD_PROM e L_INCR_LEGAL       *
*                 |                 |     | (unicamente L_KEY_UDT = 'CO'). Se *
*                 |                 |     | construye L_CLAVE_CO con sufijo   *
*                 |                 |     | _GE_MINR1/_LT_MINR1 o             *
*                 |                 |     | _GE_MITADPROM/_LT_MITADPROM segun *
*                 |                 |     | la condicion. GET_TABLE_VALUE     *
*                 |                 |     | sobre GB_CMP_CO_RANGOS_MERITO usa *
*                 |                 |     | L_CLAVE_CO (no L_CLAVE) para      *
*                 |                 |     | Colombia. Ningun texto            *
*                 |                 |     | hardcodeado en formula.           *
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
DEFAULT FOR PER_ASG_DATE_START IS '1900/01/01' (date)
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

l_log = SET_LOG('*** INICIO GB_CMP_INCRM_MERITO_RANGO_R1 ***')
L_ASG_ID = CMP_IVR_ASSIGNMENT_ID[1]
l_log = SET_LOG('Assignment ID segun input : ' || TO_CHAR(L_ASG_ID))
L_CTX_ASG = GET_CONTEXT(HR_ASSIGNMENT_ID, -1)
l_log = SET_LOG('Assignment ID segun contexto interno (HR_ASSIGNMENT_ID): ' || TO_CHAR(L_CTX_ASG))

/*============================================================================
  LEGAL EMPLOYER, KEY UDT POR PAIS Y FECHA ACOTADA AL CIERRE DEL CICLO
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
  PROMEDIO POR PAIS
============================================================================*/
L_PROM = TO_NUM(GET_TABLE_VALUE('GB_CMP_LAC_LAS_INCREMENTO_MERITO', 'Incremento_Promedio', L_KEY_UDT, '0'))
l_log = SET_LOG('Promedio: ' || TO_CHAR(L_PROM))

/*============================================================================
  UMBRALES E INCREMENTO LEGAL - Unicamente para Colombia (L_KEY_UDT = 'CO')
============================================================================*/
IF L_KEY_UDT = 'CO' THEN
(
    IF L_PROM > 10 THEN
        L_MIN_R1 = L_PROM - 3
    ELSE IF L_PROM >= 5 AND L_PROM <= 10 THEN
        L_MIN_R1 = L_PROM * 0.70
    ELSE
        L_MIN_R1 = L_PROM - 1.5

    L_MITAD_PROM = L_PROM / 2

    L_INCR_LEGAL_TXT = GET_TABLE_VALUE('GB_CMP_LAC_LAS_INCREMENTO_MERITO', 'Incremento_Legal', L_KEY_UDT, '0')
    L_INCR_LEGAL     = TO_NUM(L_INCR_LEGAL_TXT)
)
ELSE
(
    L_MIN_R1          = 0
    L_MITAD_PROM      = 0
    L_INCR_LEGAL_TXT  = '0'
    L_INCR_LEGAL      = 0
)

l_log = SET_LOG('Minimo Rango 1: ' || TO_CHAR(L_MIN_R1))
l_log = SET_LOG('Mitad Incremento Promedio: ' || TO_CHAR(L_MITAD_PROM))
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
    l_log = SET_LOG('Registros external data: ' || TO_CHAR(L_IDX))

    WHILE L_IDX >= 1 LOOP
    (
        L_EXT_VAL = CMP_EXTERNAL_WORKER_DATA_RGE_ASG_VALUE1[L_IDX]
        l_log = SET_LOG('EXT_VAL idx ' || TO_CHAR(L_IDX) || ': ' || L_EXT_VAL)

        IF L_EXT_VAL != 'N/A' THEN
        (
            L_EVAL_MAPPED = GET_TABLE_VALUE('GB_CMP_LAC_LAS_CALIFICAC_MERITO', 'Calificacion_Texto', L_EXT_VAL, '0')
            l_log = SET_LOG('EVAL_MAPPED idx ' || TO_CHAR(L_IDX) || ': ' || L_EVAL_MAPPED)

            IF L_EVAL_MAPPED != 'N/A' AND L_EVAL_MAPPED != '0' THEN
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

l_log = SET_LOG('Tipo contrato: ' || L_TIPO_CONTRATO)
l_log = SET_LOG('Hire Date: '     || TO_CHAR(L_HIRE_DATE, 'YYYY/MM/DD'))
l_log = SET_LOG('Original Date of Hire: ' || TO_CHAR(PER_ASG_REL_ORIGINAL_DATE_OF_HIRE, 'YYYY/MM/DD'))
l_log = SET_LOG('Grade ID: '      || TO_CHAR(L_GRADE))
l_log = SET_LOG('Sueldo (crudo): ' || TO_CHAR(L_SUELDO))

/*============================================================================
  DIVISOR Y CONVERSION DE SUELDO POR PERIODICIDAD DE PAIS
============================================================================*/
IF L_KEY_UDT = 'CO' OR L_KEY_UDT = 'EC' OR L_KEY_UDT = 'AR' OR L_KEY_UDT = 'PE' OR L_KEY_UDT = 'PY' THEN
(
    L_SUELDO  = L_SUELDO
)
ELSE
(
    L_SUELDO  = L_SUELDO * 30.4168
)

L_DIVISOR = 30

/*============================================================================
  CALCULO APERTURA
============================================================================*/
L_PARAM_PER = '|=PERSON_ID=' || TO_CHAR(L_PER_ID) || '|P_ASSIGNMENT_ID=' || TO_CHAR(L_CTX_ASG) || '|P_EFFECTIVE_DATE=' || TO_CHAR(L_FECHA_CONTEXTO, 'YYYY/MM/DD')
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

/*============================================================================
  DETECCION DE PROMOCION POR RETROFIT
============================================================================*/
PROMOTION_START_DATE = ADD_MONTHS(L_PL_END_DATE, -5)
PROMOTION_END_DATE   = HR_EXTRACT_DATE

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
        OR L_RC = '098'
        OR L_RC = 'ES098'
        OR L_RC = 'ES98'
        OR L_RC = 'BUK_30'
        OR L_RC = 'INTERNREC'
        OR L_RC = 'REORG'
        OR L_RC = 'WORKERREQ'
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
  CLAVE UDT (SIN CAMBIOS) - usada por GET_TABLE_VALUE sobre
  GB_CMP_LAS_LAC_RANGOS_MERITO para todo pais con L_KEY_UDT != 'CO'
============================================================================*/
IF L_CONDICION = 'Promotion' AND (L_EVAL_TXT = 'Sobresaliente' OR L_EVAL_TXT = 'Supera' OR L_EVAL_TXT = 'Cumple con lo esperado') THEN
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
  CLAVE COLOMBIA (NUEVO) - calcula la comparacion contra Incremento_Legal
  y construye la key con sufijo. Solo se calcula si L_KEY_UDT = 'CO'.
============================================================================*/
IF L_KEY_UDT = 'CO' THEN
(
    IF L_CONDICION = 'Promotion' AND L_EVAL_TXT = 'Sobresaliente' THEN
        L_CLAVE_CO = 'Sobresaliente_Prom'
    ELSE IF L_CONDICION = 'NonPerm' THEN
    (
        IF L_INCR_LEGAL > L_MIN_R1 THEN
            L_CLAVE_CO = 'NonPerm_GE_MINR1'
        ELSE
            L_CLAVE_CO = 'NonPerm_LT_MINR1'
    )
    ELSE IF L_CONDICION = 'NewHire' THEN
    (
        IF L_INCR_LEGAL > L_MIN_R1 THEN
            L_CLAVE_CO = 'NewHire_GE_MINR1'
        ELSE
            L_CLAVE_CO = 'NewHire_LT_MINR1'
    )
    ELSE IF L_EVAL_TXT = 'N/A' THEN
    (
        IF L_INCR_LEGAL > L_MIN_R1 THEN
            L_CLAVE_CO = 'SinEval_GE_MINR1'
        ELSE
            L_CLAVE_CO = 'SinEval_LT_MINR1'
    )
    ELSE IF L_EVAL_TXT = 'Exit' OR L_EVAL_TXT = 'Salida' THEN
        L_CLAVE_CO = 'Salida'
    ELSE IF L_EVAL_TXT = 'Necesita mejora' OR L_EVAL_TXT = 'Por debajo de lo esperado' THEN
    (
        IF L_INCR_LEGAL > L_MITAD_PROM THEN
            L_CLAVE_CO = L_EVAL_TXT || '_GE_MITADPROM'
        ELSE
            L_CLAVE_CO = L_EVAL_TXT || '_LT_MITADPROM'
    )
    ELSE IF L_EVAL_TXT = 'Sobresaliente' AND L_APERTURA < 100 THEN
        L_CLAVE_CO = 'Sobresaliente_LT100'
    ELSE IF L_EVAL_TXT = 'Sobresaliente' AND L_APERTURA >= 100 THEN
    (
        IF L_INCR_LEGAL > L_MIN_R1 THEN
            L_CLAVE_CO = 'Sobresaliente_GE100_GE_MINR1'
        ELSE
            L_CLAVE_CO = 'Sobresaliente_GE100_LT_MINR1'
    )
    ELSE IF L_EVAL_TXT = 'Cumple con lo esperado' AND L_APERTURA < 100 THEN
    (
        IF L_INCR_LEGAL > L_MIN_R1 THEN
            L_CLAVE_CO = 'Cumple con lo esperado_LT100_GE_MINR1'
        ELSE
            L_CLAVE_CO = 'Cumple con lo esperado_LT100_LT_MINR1'
    )
    ELSE IF L_EVAL_TXT = 'Cumple con lo esperado' AND L_APERTURA >= 100 THEN
    (
        IF L_INCR_LEGAL > L_MIN_R1 THEN
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
============================================================================*/
IF L_KEY_UDT = 'CO' THEN
    L_RANGO_OUTPUT = GET_TABLE_VALUE('GB_CMP_CO_RANGOS_MERITO', 'Texto_Rango', L_CLAVE_CO)
ELSE
    L_RANGO_OUTPUT = GET_TABLE_VALUE('GB_CMP_LAS_LAC_RANGOS_MERITO', 'Texto_Rango', L_CLAVE)

l_log = SET_LOG('*** RESULTADO RANGO: ' || L_RANGO_OUTPUT || ' ***')
RETURN L_RANGO_OUTPUT