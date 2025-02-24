/*

	Advance Disease is a system for Virologist to Engineer their own disease with symptoms that have effects and properties
	which add onto the overall disease.

	If you need help with creating new symptoms or expanding the advance disease, ask for Giacom on #coderbus.

*/




/*

	PROPERTIES

 */

/datum/disease/advance
	name = "Unknown" // We will always let our Virologist name our disease.
	desc = "An engineered disease which can contain a multitude of symptoms."
	form = "Advance Disease" // Will let med-scanners know that this disease was engineered.
	agent = "advance microbes"
	max_stages = 5
	spread_text = "Unknown"
	viable_mobtypes = list(/mob/living/carbon/human, /mob/living/carbon/monkey)

	// NEW VARS
	var/list/properties = list()
	var/list/symptoms = list() // The symptoms of the disease.
	var/id = ""
	var/processing = FALSE
	var/mutable = TRUE //set to FALSE to prevent most in-game methods of altering the disease via virology
	var/oldres
	// The order goes from easy to cure to hard to cure.
	var/static/list/advance_cures = 	list(
																		list(	// level 1 basic cures. Can be found in the chem dispenser and harmless. tg unchanged.
										/datum/reagent/copper, 
										/datum/reagent/silver, 
										/datum/reagent/iodine, 
										/datum/reagent/iron, 
										/datum/reagent/carbon
									),
									list(	// level 2 normal cures. May have some side effects. again found in the chem dispenser. tg unchanged.
										/datum/reagent/potassium, 
										/datum/reagent/consumable/ethanol, 
										/datum/reagent/lithium, 
										/datum/reagent/silicon, 
										/datum/reagent/bromine
									),
									list(	// level 3 runaround cures. requires you to run around a bit, but still easy to obtain. Usually found at the bar. mostly tg unchanged.
										/datum/reagent/consumable/sodiumchloride, 
										/datum/reagent/consumable/sugar, 
										/datum/reagent/consumable/orangejuice, 
										/datum/reagent/consumable/tomatojuice, 
										/datum/reagent/consumable/milk, 
										/datum/reagent/drug/nicotine
									),
									list(	//level 4 Vendor cures. Usually limited, but can be made in chemistry.
										/datum/reagent/medicine/spaceacillin, 
										/datum/reagent/medicine/salglu_solution, 
										/datum/reagent/medicine/epinephrine, 
										/datum/reagent/medicine/charcoal, 
										/datum/reagent/lye, 
										/datum/reagent/space_cleaner/sterilizine, 
										/datum/reagent/medicine/morphine, 
										/datum/reagent/medicine/insulin,
										/datum/reagent/toxin/plantbgone
									),
									list(	//level 5 chemical cures that require minor knowledge to obtain. These are mostly tg level 5 AND 6, since I am planning to make 6+ cures harder to get/be toxic otherwise
										/datum/reagent/oil, 
										/datum/reagent/medicine/synaptizine, 
										/datum/reagent/medicine/mannitol, 
										/datum/reagent/drug/space_drugs, 
										/datum/reagent/cryptobiolin, 
										/datum/reagent/phenol, 
										/datum/reagent/medicine/inacusiate, 
										/datum/reagent/medicine/oculine, 
										/datum/reagent/medicine/antihol
										
									),
									list(	// level 6
										/datum/reagent/consumable/capsaicin, 
										/datum/reagent/consumable/condensedcapsaicin, 
										/datum/reagent/concentrated_barbers_aid, 
										/datum/reagent/barbers_aid, 
										/datum/reagent/stabilizing_agent, 
										/datum/reagent/medicine/ephedrine, 
										/datum/reagent/toxin/bad_food,
										/datum/reagent/medicine/clonexadone,
										/datum/reagent/consumable/enzyme
									),
									list(	// level 7 these are mostly poisons.
										/datum/reagent/toxin/mutagen, 
										/datum/reagent/pax, 
										/datum/reagent/drug/happiness, 
										/datum/reagent/toxin/lipolicide, 
										/datum/reagent/toxin/fentanyl, 
										/datum/reagent/toxin/sulfonal, 
										/datum/reagent/toxin/histamine, 
										/datum/reagent/medicine/atropine,
										/datum/reagent/toxin/acid/fluacid
									),
									list(	// level 8 you will need to run around to get these.
										/datum/reagent/consumable/entpoly, 
										/datum/reagent/consumable/tinlux, 
										/datum/reagent/consumable/vitfro, 
										/datum/reagent/toxin/minttoxin, 
										/datum/reagent/toxin/mutetoxin, 
										/datum/reagent/toxin/bonehurtingjuice,
										/datum/reagent/water/holywater,
										/datum/reagent/consumable/astrotame,
										/datum/reagent/colorful_reagent,
										/datum/reagent/glitter/pink,
										/datum/reagent/glitter/white,
										/datum/reagent/glitter/blue
									),
									list(	// level 9 CMO, you didn't empty your hypospray, right?
										/datum/reagent/consumable/honey, 
										/datum/reagent/medicine/omnizine, 
										/datum/reagent/medicine/earthsblood,
										/datum/reagent/consumable/ethanol/lizardwine,
										/datum/reagent/medicine/strange_reagent,
										/datum/reagent/consumable/liquidelectricity
									),
									list(	// level 10 oh god....
										/datum/reagent/medicine/lavaland_extract, 
										/datum/reagent/toxin/amanitin,
										/datum/reagent/medicine/pyroxadone,
										/datum/reagent/toxin/slimejelly,
										/datum/reagent/teslium/energized_jelly,
										/datum/reagent/growthserum
										
										
									),
									list(	//level 11 why.... (I just stick here chemicals that should be extremely hard to obtain. Because gold? Pffff, come on!)
										/datum/reagent/consumable/ethanol/blazaam, 
										/datum/reagent/toxin/ghoulpowder, 
										/datum/reagent/medicine/regen_jelly,
										/datum/reagent/royal_bee_jelly,
										/datum/chemical_reaction/mimesbane,
										/datum/reagent/medicine/lavaland_extract,
										/datum/reagent/tranquility
									)
								)

/*

	OLD PROCS

 */

/datum/disease/advance/New()
	Refresh()

/datum/disease/advance/Destroy()
	if(processing)
		for(var/datum/symptom/S in symptoms)
			S.End(src)
	return ..()

/datum/disease/advance/try_infect(var/mob/living/infectee, make_copy = TRUE)
	//see if we are more transmittable than enough diseases to replace them
	//diseases replaced in this way do not confer immunity
	var/list/advance_diseases = list()
	for(var/datum/disease/advance/P in infectee.diseases)
		advance_diseases += P
	var/replace_num = advance_diseases.len + 1 - DISEASE_LIMIT //amount of diseases that need to be removed to fit this one
	if(replace_num > 0)
		sortTim(advance_diseases, /proc/cmp_advdisease_resistance_asc)
		for(var/i in 1 to replace_num)
			var/datum/disease/advance/competition = advance_diseases[i]
			if(totalTransmittable() > competition.totalResistance())
				competition.cure(FALSE)
			else
				return FALSE //we are not strong enough to bully our way in
	infect(infectee, make_copy)
	return TRUE

// Randomly pick a symptom to activate.
/datum/disease/advance/stage_act()
	..()
	if(carrier)
		return

	if(symptoms?.len)

		if(!processing)
			processing = TRUE
			for(var/datum/symptom/S in symptoms)
				S.Start(src)

		for(var/datum/symptom/S in symptoms)
			S.Activate(src)

// Tell symptoms stage changed
/datum/disease/advance/update_stage(new_stage)
	..()
	for(var/datum/symptom/S in symptoms)
		S.on_stage_change(new_stage, src)

// Compares type then ID.
/datum/disease/advance/IsSame(datum/disease/advance/D)

	if(!(istype(D, /datum/disease/advance)))
		return 0

	if(GetDiseaseID() != D.GetDiseaseID())
		return 0
	return 1

// Returns the advance disease with a different reference memory.
/datum/disease/advance/Copy()
	var/datum/disease/advance/A = ..()
	QDEL_LIST(A.symptoms)
	for(var/datum/symptom/S in symptoms)
		A.symptoms += S.Copy()
	A.properties = properties.Copy()
	A.id = id
	A.mutable = mutable
	//this is a new disease starting over at stage 1, so processing is not copied
	return A

//Describe this disease to an admin in detail (for logging)
/datum/disease/advance/admin_details()
	var/list/name_symptoms = list()
	for(var/datum/symptom/S in symptoms)
		name_symptoms += S.name
	return "[name] sym:[english_list(name_symptoms)] r:[totalResistance()] s:[totalStealth()] ss:[totalStageSpeed()] t:[totalTransmittable()]"

/*

	NEW PROCS

 */

// Mix the symptoms of two diseases (the src and the argument)
/datum/disease/advance/proc/Mix(datum/disease/advance/D)
	if(!(IsSame(D)))
		var/list/possible_symptoms = shuffle(D.symptoms)
		for(var/datum/symptom/S in possible_symptoms)
			AddSymptom(S.Copy())

/datum/disease/advance/proc/HasSymptom(datum/symptom/S)
	for(var/datum/symptom/symp in symptoms)
		if(symp.type == S.type)
			return 1
	return 0

// Will generate new unique symptoms, use this if there are none. Returns a list of symptoms that were generated.
/datum/disease/advance/proc/GenerateSymptoms(level_min, level_max, amount_get = 0)

	var/list/generated = list() // Symptoms we generated.

	// Generate symptoms. By default, we only choose non-deadly symptoms.
	var/list/possible_symptoms = list()
	for(var/symp in SSdisease.list_symptoms)
		var/datum/symptom/S = new symp
		if(S.naturally_occuring && S.level >= level_min && S.level <= level_max)
			if(!HasSymptom(S))
				possible_symptoms += S

	if(!possible_symptoms.len)
		return generated

	// Random chance to get more than one symptom
	var/number_of = amount_get
	if(!amount_get)
		number_of = 1
		while(prob(20))
			number_of += 1

	for(var/i = 1; number_of >= i && possible_symptoms.len; i++)
		generated += pick_n_take(possible_symptoms)

	return generated

/datum/disease/advance/proc/Refresh(new_name = FALSE)
	GenerateProperties()
	AssignProperties()
	id = null

	var/the_id = GetDiseaseID()
	if(!SSdisease.archive_diseases[the_id])
		SSdisease.archive_diseases[the_id] = src // So we don't infinite loop
		SSdisease.archive_diseases[the_id] = Copy()
		if(new_name)
			AssignName()

//Generate disease properties based on the effects. Returns an associated list.
/datum/disease/advance/proc/GenerateProperties()
	properties = list("resistance" = 0, "stealth" = 0, "stage_rate" = 0, "transmittable" = 0, "severity" = 0)

	for(var/datum/symptom/S in symptoms)
		properties["resistance"] += S.resistance
		properties["stealth"] += S.stealth
		properties["stage_rate"] += S.stage_speed
		properties["transmittable"] += S.transmittable
		if(!S.neutered)
			properties["severity"] = max(properties["severity"], S.severity) // severity is based on the highest severity non-neutered symptom

// Assign the properties that are in the list.
/datum/disease/advance/proc/AssignProperties()

	if(properties && properties.len)
		if(properties["stealth"] >= 2)
			visibility_flags |= HIDDEN_SCANNER
		else
			visibility_flags &= ~HIDDEN_SCANNER

		SetSpread(CLAMP(2 ** (properties["transmittable"] - symptoms.len), DISEASE_SPREAD_BLOOD, DISEASE_SPREAD_AIRBORNE))

		permeability_mod = max(CEILING(0.4 * properties["transmittable"], 1), 1)
		cure_chance = 15 - CLAMP(properties["resistance"], -5, 5) // can be between 10 and 20
		stage_prob = max(properties["stage_rate"], 2)
		SetSeverity(properties["severity"])
		GenerateCure(properties)
	else
		CRASH("Our properties were empty or null!")


// Assign the spread type and give it the correct description.
/datum/disease/advance/proc/SetSpread(spread_id)
	switch(spread_id)
		if(DISEASE_SPREAD_NON_CONTAGIOUS)
			spread_flags = DISEASE_SPREAD_NON_CONTAGIOUS
			spread_text = "None"
		if(DISEASE_SPREAD_SPECIAL)
			spread_flags = DISEASE_SPREAD_SPECIAL
			spread_text = "None"
		if(DISEASE_SPREAD_BLOOD)
			spread_flags = DISEASE_SPREAD_BLOOD
			spread_text = "Blood"
		if(DISEASE_SPREAD_CONTACT_FLUIDS)
			spread_flags = DISEASE_SPREAD_BLOOD | DISEASE_SPREAD_CONTACT_FLUIDS
			spread_text = "Fluids"
		if(DISEASE_SPREAD_CONTACT_SKIN)
			spread_flags = DISEASE_SPREAD_BLOOD | DISEASE_SPREAD_CONTACT_FLUIDS | DISEASE_SPREAD_CONTACT_SKIN
			spread_text = "On contact"
		if(DISEASE_SPREAD_AIRBORNE)
			spread_flags = DISEASE_SPREAD_BLOOD | DISEASE_SPREAD_CONTACT_FLUIDS | DISEASE_SPREAD_CONTACT_SKIN | DISEASE_SPREAD_AIRBORNE
			spread_text = "Airborne"

/datum/disease/advance/proc/SetSeverity(level_sev)

	switch(level_sev)

		if(-INFINITY to 0)
			severity = DISEASE_SEVERITY_POSITIVE
		if(1)
			severity = DISEASE_SEVERITY_NONTHREAT
		if(2)
			severity = DISEASE_SEVERITY_MINOR
		if(3)
			severity = DISEASE_SEVERITY_MEDIUM
		if(4)
			severity = DISEASE_SEVERITY_HARMFUL
		if(5)
			severity = DISEASE_SEVERITY_DANGEROUS
		if(6 to INFINITY)
			severity = DISEASE_SEVERITY_BIOHAZARD
		else
			severity = "Unknown"


// Will generate a random cure, the less resistance the symptoms have, the harder the cure.
/datum/disease/advance/proc/GenerateCure()
	if(properties && properties.len)
		var/res = CLAMP(properties["resistance"] - (symptoms.len / 2), 1, advance_cures.len)

		if(res == oldres)
			return
		cures = list(pick(advance_cures[res]))
		oldres = res

		// Get the cure name from the cure_id
		var/datum/reagent/D = GLOB.chemical_reagents_list[cures[1]]
		cure_text = D.name

// Randomly generate a symptom, has a chance to lose or gain a symptom.
/datum/disease/advance/proc/Evolve(min_level, max_level, ignore_mutable = FALSE)
	if(!mutable && !ignore_mutable)
		return
	var/s = safepick(GenerateSymptoms(min_level, max_level, 1))
	if(s)
		AddSymptom(s)
		Refresh(TRUE)
	return

// Randomly remove a symptom.
/datum/disease/advance/proc/Devolve(ignore_mutable = FALSE)
	if(!mutable && !ignore_mutable)
		return
	if(symptoms.len > 1)
		var/s = safepick(symptoms)
		if(s)
			RemoveSymptom(s)
			Refresh(TRUE)

// Randomly neuter a symptom.
/datum/disease/advance/proc/Neuter(ignore_mutable = FALSE)
	if(!mutable && !ignore_mutable)
		return
	if(symptoms.len)
		var/s = safepick(symptoms)
		if(s)
			NeuterSymptom(s)
			Refresh(TRUE)

// Name the disease.
/datum/disease/advance/proc/AssignName(name = "Unknown")
	Refresh()
	var/datum/disease/advance/A = SSdisease.archive_diseases[GetDiseaseID()]
	A.name = name
	for(var/datum/disease/advance/AD in SSdisease.active_diseases)
		AD.Refresh()

// Return a unique ID of the disease.
/datum/disease/advance/GetDiseaseID()
	if(!id)
		var/list/L = list()
		for(var/datum/symptom/S in symptoms)
			if(S.neutered)
				L += "[S.id]N"
			else
				L += S.id
		L = sortList(L) // Sort the list so it doesn't matter which order the symptoms are in.
		var/result = jointext(L, ":")
		id = result
	return id


// Add a symptom, if it is over the limit we take a random symptom away and add the new one.
/datum/disease/advance/proc/AddSymptom(datum/symptom/S)

	if(HasSymptom(S))
		return

	if(!(symptoms.len < (VIRUS_SYMPTOM_LIMIT - 1) + rand(-1, 1)))
		RemoveSymptom(pick(symptoms))
	symptoms += S
	S.OnAdd(src)

// Simply removes the symptom.
/datum/disease/advance/proc/RemoveSymptom(datum/symptom/S)
	symptoms -= S
	S.OnRemove(src)

// Neuter a symptom, so it will only affect stats
/datum/disease/advance/proc/NeuterSymptom(datum/symptom/S)
	if(!S.neutered)
		S.neutered = TRUE
		S.name += " (neutered)"
		S.OnRemove(src)

/*

	Static Procs

*/

// Mix a list of advance diseases and return the mixed result.
/proc/Advance_Mix(var/list/D_list)
	var/list/diseases = list()

	for(var/datum/disease/advance/A in D_list)
		diseases += A.Copy()

	if(!diseases.len)
		return null
	if(diseases.len <= 1)
		return pick(diseases) // Just return the only entry.

	var/i = 0
	// Mix our diseases until we are left with only one result.
	while(i < 20 && diseases.len > 1)

		i++

		var/datum/disease/advance/D1 = pick(diseases)
		diseases -= D1

		var/datum/disease/advance/D2 = pick(diseases)
		D2.Mix(D1)

	 // Should be only 1 entry left, but if not let's only return a single entry
	var/datum/disease/advance/to_return = pick(diseases)
	to_return.Refresh(1)
	return to_return

/proc/SetViruses(datum/reagent/R, list/data)
	if(data)
		var/list/preserve = list()
		if(istype(data) && data["viruses"])
			for(var/datum/disease/A in data["viruses"])
				preserve += A.Copy()
			R.data = data.Copy()
		if(preserve.len)
			R.data["viruses"] = preserve

/proc/AdminCreateVirus(client/user)

	if(!user)
		return

	var/i = VIRUS_SYMPTOM_LIMIT

	var/datum/disease/advance/D = new(0, null)
	D.symptoms = list()

	var/list/symptoms = list()
	symptoms += "Done"
	symptoms += SSdisease.list_symptoms.Copy()
	do
		if(user)
			var/symptom = input(user, "Choose a symptom to add ([i] remaining)", "Choose a Symptom") in symptoms
			if(isnull(symptom))
				return
			else if(istext(symptom))
				i = 0
			else if(ispath(symptom))
				var/datum/symptom/S = new symptom
				if(!D.HasSymptom(S))
					D.symptoms += S
					i -= 1
	while(i > 0)

	if(D.symptoms.len > 0)

		var/new_name = stripped_input(user, "Name your new disease.", "New Name")
		if(!new_name)
			return
		D.AssignName(new_name)
		D.Refresh()

		for(var/datum/disease/advance/AD in SSdisease.active_diseases)
			AD.Refresh()

		for(var/mob/living/carbon/human/H in shuffle(GLOB.alive_mob_list))
			if(!is_station_level(H.z))
				continue
			if(!H.HasDisease(D))
				H.ForceContractDisease(D)
				break

		var/list/name_symptoms = list()
		for(var/datum/symptom/S in D.symptoms)
			name_symptoms += S.name
		message_admins("[key_name_admin(user)] has triggered a custom virus outbreak of [D.admin_details()]")
		log_virus("[key_name(user)] has triggered a custom virus outbreak of [D.admin_details()]!")


/datum/disease/advance/proc/totalStageSpeed()
	return properties["stage_rate"]

/datum/disease/advance/proc/totalStealth()
	return properties["stealth"]

/datum/disease/advance/proc/totalResistance()
	return properties["resistance"]

/datum/disease/advance/proc/totalTransmittable()
	return properties["transmittable"]
