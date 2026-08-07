/**********************************************************************
FORMULA NAME      : GB_CMP_NEW_HIRE_RETROFIT
CREATED_BY        : IT-GLOBAL
CREATION_DATE     : (segun version original)
LAST_UPDATE_DATE  : 10 de Julio del 2026
FORMULA TYPE      : Compensation Default and Override
DESCRIPTION       : Identifica si el colaborador es New Hire, usando la misma
                    ventana de 5 meses antes del cierre del plan ya validada
                    en GB_CMP_INCRM_MERITO_RANGO_R4. Usa ORIGINAL_DATE_OF_HIRE
                    acotado via contexto interno de asignacion (HR_ASSIGNMENT_ID)
                    para evitar discrepancia con asignaciones historicas.
**********************************************************************/

INPUTS ARE
CMP_IV_PLAN_EXTRACTION_DATE (text),
CMP_IV_PLAN_START_DATE (text),
CMP_IV_PLAN_END_DATE (text)

DEFAULT FOR CMP_IV_PLAN_EXTRACTION_DATE IS '4012/01/01'
DEFAULT FOR CMP_IV_PLAN_START_DATE IS '1900/01/01'
DEFAULT FOR CMP_IV_PLAN_END_DATE IS '4012/01/01'
DEFAULT FOR PER_ASG_EFFECTIVE_START_DATE IS '1981/05/15' (date)
DEFAULT FOR PER_PER_LATEST_REHIRE_DATE IS '1901/01/01' (date)
DEFAULT FOR PER_ASG_REL_ORIGINAL_DATE_OF_HIRE IS '1901/01/01' (date)

L_DEFAULT_VALUE = 'N'
L_NEW_HIRE = 'N'

HR_EXTRACT_DATE = TO_DATE(CMP_IV_PLAN_EXTRACTION_DATE, 'YYYY/MM/DD')
L_PL_START_DATE = TO_DATE(CMP_IV_PLAN_START_DATE, 'YYYY/MM/DD')
L_PL_END_DATE   = TO_DATE(CMP_IV_PLAN_END_DATE, 'YYYY/MM/DD')

l_log = SET_LOG('*** INICIO GB_CMP_NEW_HIRE_RETROFIT ***')
l_log = SET_LOG('Fecha extraccion: ' || TO_CHAR(HR_EXTRACT_DATE))
l_log = SET_LOG('Fecha inicio plan: ' || TO_CHAR(L_PL_START_DATE))
l_log = SET_LOG('Fecha fin plan: ' || TO_CHAR(L_PL_END_DATE))

/*=== DIAGNOSTICO ASSIGNMENT (mismo patron validado) ===*/
L_CTX_ASG = GET_CONTEXT(HR_ASSIGNMENT_ID, -1)
l_log = SET_LOG('Assignment ID segun contexto interno (HR_ASSIGNMENT_ID): ' || TO_CHAR(L_CTX_ASG))

L_HIRE_DATE = PER_ASG_EFFECTIVE_START_DATE
L_ORIGINAL_HIRE_DATE = PER_ASG_REL_ORIGINAL_DATE_OF_HIRE
L_LATEST_REHIRE_DATE = PER_PER_LATEST_REHIRE_DATE

l_log = SET_LOG('Assignment Start Date: ' || TO_CHAR(L_HIRE_DATE, 'YYYY/MM/DD'))
l_log = SET_LOG('Original Date of Hire: ' || TO_CHAR(L_ORIGINAL_HIRE_DATE, 'YYYY/MM/DD'))
l_log = SET_LOG('Latest Rehire Date: ' || TO_CHAR(L_LATEST_REHIRE_DATE, 'YYYY/MM/DD'))

/*============================================================================
  VENTANA DE 5 MESES ANTES DEL CIERRE DEL PLAN
  (misma logica validada en GB_CMP_INCRM_MERITO_RANGO_R4)
============================================================================*/
L_CINCO_MESES = ADD_MONTHS(L_PL_END_DATE, -5)
l_log = SET_LOG('Ventana New Hire (5 meses antes de cierre): ' || TO_CHAR(L_CINCO_MESES, 'YYYY/MM/DD'))

IF L_ORIGINAL_HIRE_DATE >= L_CINCO_MESES THEN
    L_NEW_HIRE = 'Y'

L_DEFAULT_VALUE = L_NEW_HIRE

l_log = SET_LOG('*** RESULTADO NEW HIRE: ' || L_NEW_HIRE || ' ***')
RETURN L_DEFAULT_VALUE