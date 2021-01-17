//This is the lowest supported version, anything below this is completely obsolete and the entire savefile will be wiped.
#define SAVEFILE_VERSION_MIN	32

//This is the current version, anything below this will attempt to update (if it's not obsolete)
//	You do not need to raise this if you are adding new values that have sane defaults.
//	Only raise this value when changing the meaning/format/name/layout of an existing value
//	where you would want the updater procs below to run
#define SAVEFILE_VERSION_MAX	38

/datum/preferences/proc/load_character(slot)
	if(!path)
		return FALSE
	if(!fexists(path))
		return FALSE
	var/savefile/S = new /savefile(path)
	if(!S)
		return FALSE
	S.cd = "/"
	if(!slot)
		slot = default_slot
	slot = sanitize_integer(slot, 1, max_save_slots, initial(default_slot))
	if(slot != default_slot)
		default_slot = slot
		WRITE_FILE(S["default_slot"] , slot)

	S.cd = "/character[slot]"
	var/needs_update = savefile_needs_update(S)
	if(needs_update == -2)		//fatal, can't load any data
		return FALSE

	//Species
	var/species_id
	READ_FILE(S["species"], species_id)
	if(species_id)
		var/newtype = GLOB.species_list[species_id]
		if(newtype)
			pref_species = new newtype


	//Character
	READ_FILE(S["real_name"], real_name)
	READ_FILE(S["gender"], gender)
	READ_FILE(S["body_type"], body_type)
	READ_FILE(S["age"], age)
	READ_FILE(S["med_record"], med_record)
	READ_FILE(S["hair_color"], hair_color)
	READ_FILE(S["facial_hair_color"], facial_hair_color)
	READ_FILE(S["eye_color"], eye_color)
	READ_FILE(S["skin_tone"], skin_tone)
	READ_FILE(S["hairstyle_name"], hairstyle)
	READ_FILE(S["facial_style_name"], facial_hairstyle)
	READ_FILE(S["underwear"], underwear)
	READ_FILE(S["underwear_color"], underwear_color)
	READ_FILE(S["undershirt"], undershirt)
	READ_FILE(S["socks"], socks)
	READ_FILE(S["backpack"], backpack)
	READ_FILE(S["jumpsuit_style"], jumpsuit_style)
	READ_FILE(S["uplink_loc"], uplink_spawn_loc)
	READ_FILE(S["playtime_reward_cloak"], playtime_reward_cloak)
	READ_FILE(S["phobia"], phobia)
	READ_FILE(S["randomise"],  randomise)
	READ_FILE(S["feature_mcolor"], features["mcolor"])
	READ_FILE(S["feature_ethcolor"], features["ethcolor"])
	READ_FILE(S["feature_lizard_tail"], features["tail_lizard"])
	READ_FILE(S["feature_lizard_snout"], features["snout"])
	READ_FILE(S["feature_lizard_horns"], features["horns"])
	READ_FILE(S["feature_lizard_frills"], features["frills"])
	READ_FILE(S["feature_lizard_spines"], features["spines"])
	READ_FILE(S["feature_lizard_body_markings"], features["body_markings"])
	READ_FILE(S["feature_lizard_legs"], features["legs"])
	READ_FILE(S["feature_moth_wings"], features["moth_wings"])
	READ_FILE(S["feature_moth_antennae"], features["moth_antennae"])
	READ_FILE(S["feature_moth_markings"], features["moth_markings"])
	READ_FILE(S["persistent_scars"] , persistent_scars)
	if(!CONFIG_GET(flag/join_with_mutant_humans))
		features["tail_human"] = "none"
		features["ears"] = "none"
	else
		READ_FILE(S["feature_human_tail"], features["tail_human"])
		READ_FILE(S["feature_human_ears"], features["ears"])

	//Custom names
	for(var/custom_name_id in GLOB.preferences_custom_names)
		var/savefile_slot_name = custom_name_id + "_name" //TODO remove this
		READ_FILE(S[savefile_slot_name], custom_names[custom_name_id])

	READ_FILE(S["preferred_ai_core_display"], preferred_ai_core_display)
	READ_FILE(S["prefered_security_department"], prefered_security_department)

	//Jobs
	READ_FILE(S["joblessrole"], joblessrole)
	//Load prefs
	READ_FILE(S["job_preferences"], job_preferences)

	//Quirks
	READ_FILE(S["all_quirks"], all_quirks)

	//try to fix any outdated data if necessary
	//preference updating will handle saving the updated data for us.
	if(needs_update >= 0)
		update_character(needs_update, S)		//needs_update == savefile_version if we need an update (positive integer)

	//Sanitize
	real_name = reject_bad_name(real_name)
	gender = sanitize_gender(gender)
	body_type = sanitize_gender(body_type, FALSE, FALSE, gender)
	if(!real_name)
		real_name = random_unique_name(gender)

	for(var/custom_name_id in GLOB.preferences_custom_names)
		var/namedata = GLOB.preferences_custom_names[custom_name_id]
		custom_names[custom_name_id] = reject_bad_name(custom_names[custom_name_id],namedata["allow_numbers"])
		if(!custom_names[custom_name_id])
			custom_names[custom_name_id] = get_default_name(custom_name_id)

	if(!features["mcolor"] || features["mcolor"] == "#000")
		features["mcolor"] = pick("FFFFFF","7F7F7F", "7FFF7F", "7F7FFF", "FF7F7F", "7FFFFF", "FF7FFF", "FFFF7F")

	if(!features["ethcolor"] || features["ethcolor"] == "#000")
		features["ethcolor"] = GLOB.color_list_ethereal[pick(GLOB.color_list_ethereal)]

	randomise = SANITIZE_LIST(randomise)

	if(gender == MALE)
		hairstyle			= sanitize_inlist(hairstyle, GLOB.hairstyles_male_list)
		facial_hairstyle			= sanitize_inlist(facial_hairstyle, GLOB.facial_hairstyles_male_list)
		underwear		= sanitize_inlist(underwear, GLOB.underwear_m)
		undershirt 		= sanitize_inlist(undershirt, GLOB.undershirt_m)
	else if(gender == FEMALE)
		hairstyle			= sanitize_inlist(hairstyle, GLOB.hairstyles_female_list)
		facial_hairstyle			= sanitize_inlist(facial_hairstyle, GLOB.facial_hairstyles_female_list)
		underwear		= sanitize_inlist(underwear, GLOB.underwear_f)
		undershirt		= sanitize_inlist(undershirt, GLOB.undershirt_f)
	else
		hairstyle			= sanitize_inlist(hairstyle, GLOB.hairstyles_list)
		facial_hairstyle			= sanitize_inlist(facial_hairstyle, GLOB.facial_hairstyles_list)
		underwear		= sanitize_inlist(underwear, GLOB.underwear_list)
		undershirt 		= sanitize_inlist(undershirt, GLOB.undershirt_list)

	socks			= sanitize_inlist(socks, GLOB.socks_list)
	age				= sanitize_integer(age, AGE_MIN, AGE_MAX, initial(age))
	hair_color			= sanitize_hexcolor(hair_color, 3, 0)
	facial_hair_color			= sanitize_hexcolor(facial_hair_color, 3, 0)
	underwear_color			= sanitize_hexcolor(underwear_color, 3, 0)
	eye_color		= sanitize_hexcolor(eye_color, 3, 0)
	skin_tone		= sanitize_inlist(skin_tone, GLOB.skin_tones)
	backpack			= sanitize_inlist(backpack, GLOB.backpacklist, initial(backpack))
	jumpsuit_style	= sanitize_inlist(jumpsuit_style, GLOB.jumpsuitlist, initial(jumpsuit_style))
	uplink_spawn_loc = sanitize_inlist(uplink_spawn_loc, GLOB.uplink_spawn_loc_list, initial(uplink_spawn_loc))
	playtime_reward_cloak = sanitize_integer(playtime_reward_cloak)
	features["mcolor"]	= sanitize_hexcolor(features["mcolor"], 3, 0)
	features["ethcolor"]	= copytext_char(features["ethcolor"], 1, 7)
	features["tail_lizard"]	= sanitize_inlist(features["tail_lizard"], GLOB.tails_list_lizard)
	features["tail_human"] 	= sanitize_inlist(features["tail_human"], GLOB.tails_list_human, "None")
	features["snout"]	= sanitize_inlist(features["snout"], GLOB.snouts_list)
	features["horns"] 	= sanitize_inlist(features["horns"], GLOB.horns_list)
	features["ears"]	= sanitize_inlist(features["ears"], GLOB.ears_list, "None")
	features["frills"] 	= sanitize_inlist(features["frills"], GLOB.frills_list)
	features["spines"] 	= sanitize_inlist(features["spines"], GLOB.spines_list)
	features["body_markings"] 	= sanitize_inlist(features["body_markings"], GLOB.body_markings_list)
	features["feature_lizard_legs"]	= sanitize_inlist(features["legs"], GLOB.legs_list, "Normal Legs")
	features["moth_wings"] 	= sanitize_inlist(features["moth_wings"], GLOB.moth_wings_list, "Plain")
	features["moth_antennae"] 	= sanitize_inlist(features["moth_antennae"], GLOB.moth_antennae_list, "Plain")
	features["moth_markings"] 	= sanitize_inlist(features["moth_markings"], GLOB.moth_markings_list, "None")

	persistent_scars = sanitize_integer(persistent_scars)

	joblessrole	= sanitize_integer(joblessrole, 1, 3, initial(joblessrole))
	//Validate job prefs
	for(var/j in job_preferences)
		if(job_preferences[j] != JP_LOW && job_preferences[j] != JP_MEDIUM && job_preferences[j] != JP_HIGH)
			job_preferences -= j

	all_quirks = SANITIZE_LIST(all_quirks)

	return TRUE

/datum/preferences/proc/save_character()
	if(!path)
		return FALSE
	var/savefile/S = new /savefile(path)
	if(!S)
		return FALSE
	S.cd = "/character[default_slot]"

	WRITE_FILE(S["version"]			, SAVEFILE_VERSION_MAX)	//load_character will sanitize any bad data, so assume up-to-date.)

	//Character
	WRITE_FILE(S["real_name"]			, real_name)
	WRITE_FILE(S["gender"]			, gender)
	WRITE_FILE(S["body_type"]		, body_type)
	WRITE_FILE(S["age"]			, age)
	WRITE_FILE(S["med_record"]			, med_record)
	WRITE_FILE(S["hair_color"]			, hair_color)
	WRITE_FILE(S["facial_hair_color"]			, facial_hair_color)
	WRITE_FILE(S["eye_color"]			, eye_color)
	WRITE_FILE(S["skin_tone"]			, skin_tone)
	WRITE_FILE(S["hairstyle_name"]			, hairstyle)
	WRITE_FILE(S["facial_style_name"]			, facial_hairstyle)
	WRITE_FILE(S["underwear"]			, underwear)
	WRITE_FILE(S["underwear_color"]			, underwear_color)
	WRITE_FILE(S["undershirt"]			, undershirt)
	WRITE_FILE(S["socks"]			, socks)
	WRITE_FILE(S["backpack"]			, backpack)
	WRITE_FILE(S["jumpsuit_style"]			, jumpsuit_style)
	WRITE_FILE(S["uplink_loc"]			, uplink_spawn_loc)
	WRITE_FILE(S["playtime_reward_cloak"]			, playtime_reward_cloak)
	WRITE_FILE(S["randomise"]		, randomise)
	WRITE_FILE(S["species"]			, pref_species.id)
	WRITE_FILE(S["phobia"], phobia)
	WRITE_FILE(S["feature_mcolor"]					, features["mcolor"])
	WRITE_FILE(S["feature_ethcolor"]					, features["ethcolor"])
	WRITE_FILE(S["feature_lizard_tail"]			, features["tail_lizard"])
	WRITE_FILE(S["feature_human_tail"]				, features["tail_human"])
	WRITE_FILE(S["feature_lizard_snout"]			, features["snout"])
	WRITE_FILE(S["feature_lizard_horns"]			, features["horns"])
	WRITE_FILE(S["feature_human_ears"]				, features["ears"])
	WRITE_FILE(S["feature_lizard_frills"]			, features["frills"])
	WRITE_FILE(S["feature_lizard_spines"]			, features["spines"])
	WRITE_FILE(S["feature_lizard_body_markings"]	, features["body_markings"])
	WRITE_FILE(S["feature_lizard_legs"]			, features["legs"])
	WRITE_FILE(S["feature_moth_wings"]			, features["moth_wings"])
	WRITE_FILE(S["feature_moth_antennae"]			, features["moth_antennae"])
	WRITE_FILE(S["feature_moth_markings"]		, features["moth_markings"])
	WRITE_FILE(S["persistent_scars"]			, persistent_scars)

	//Custom names
	for(var/custom_name_id in GLOB.preferences_custom_names)
		var/savefile_slot_name = custom_name_id + "_name" //TODO remove this
		WRITE_FILE(S[savefile_slot_name],custom_names[custom_name_id])

	WRITE_FILE(S["preferred_ai_core_display"] ,  preferred_ai_core_display)
	WRITE_FILE(S["prefered_security_department"] , prefered_security_department)

	//Jobs
	WRITE_FILE(S["joblessrole"]		, joblessrole)
	//Write prefs
	WRITE_FILE(S["job_preferences"] , job_preferences)

	//Quirks
	WRITE_FILE(S["all_quirks"]			, all_quirks)

	return TRUE