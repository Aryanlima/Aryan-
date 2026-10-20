--!strict
--[[
	FeatureFlags: interruptores unicos de funciones con riesgo de cumplimiento. Un solo archivo, sin logica.

	paidLuckEnabled (por defecto FALSE en la v1; decision D9 del informe maestro):
	  La "suerte" comprable con Robux (Pase Suerte+ y Cebo de Suerte) cuenta como objeto aleatorio de pago
	  (ROBLOX/research/03 2.1): exige odds numericas dinamicas, PolicyService y alternativa por pais. Se activara en la
	  v1.5 cuando eso este probado con el Player Emulator.

	  Con el flag APAGADO:
	    * esos dos objetos NO aparecen en la tienda ni se pueden comprar (Shop los trata como `enabled = false`);
	    * si llegara un recibo antiguo de uno de ellos, ProcessReceipt lo RECHAZA con NotProcessedYet y no
	      concede nada (queda sin resolver: ver README, "Recibos antiguos de suerte");
	    * ninguna fuente de suerte de pago cuenta en la tirada ni aparece en la UI de probabilidades
	      (la suerte GRATUITA de las canas, el minijuego y los eventos sigue funcionando y se muestra).
	  La logica de suerte y sus tests se conservan: tests/GameLogic.spec.luau y tests/Monetization.spec.luau
	  cubren flag = false (v1) y flag = true (v1.5).

	// REVIEW(money): cambiar este flag a true es una decision de cumplimiento, no solo tecnica.
]]

return {
	paidLuckEnabled = false,
}
