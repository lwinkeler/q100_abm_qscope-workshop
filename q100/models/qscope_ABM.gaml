/**
* Name: q100_ABM
*
* Authors: lennartwinkeler, davidunland, philippolaleye
* Institution: University of Bremen, Department of Resilient Energy Systems
* Date: 2022-03-18
*  
*/


model q100


global {

	
	
	float step <- 1 #day;
	date starting_date <- date([2020,1,1,0,0,0]);
	graph network <- graph([]);
	geometry shape <- envelope(shape_file_typologiezonen);
	

	// load shapefiles
	file shape_file_buildings <- file("../includes/Shapefiles/bestandsgebaeude_export.shp");
	file shape_file_typologiezonen <- file("../includes/Shapefiles/Typologiezonen.shp");

	
	list attributes_possible_sources <- ["Kataster_A", "Kataster_T"]; 
	string attributes_source <- attributes_possible_sources[1];

	matrix<float> decision_500_1000 <- matrix<float>(csv_file("../includes/csv-data_socio/2021-11-18_V1/decision-making_500-1000_V1.csv", ",", float, true));
	matrix<float> decision_1000_1500 <- matrix<float>(csv_file("../includes/csv-data_socio/2021-11-18_V1/decision-making_1000-1500_V1.csv", ",", float, true));
	matrix<float> decision_1500_2000 <- matrix<float>(csv_file("../includes/csv-data_socio/2021-11-18_V1/decision-making_1500-2000_V1.csv", ",", float, true));
	matrix<float> decision_2000_3000 <- matrix<float>(csv_file("../includes/csv-data_socio/2021-11-18_V1/decision-making_2000-3000_V1.csv", ",", float, true));
	matrix<float> decision_3000_4000 <- matrix<float>(csv_file("../includes/csv-data_socio/2021-11-18_V1/decision-making_3000-4000_V1.csv", ",", float, true));
	matrix<float> decision_4000etc <- matrix<float>(csv_file("../includes/csv-data_socio/2021-11-18_V1/decision-making_4000etc_V1.csv", ",", float, true));
	
	matrix<int> network_employed <- matrix<int>(csv_file("../includes/csv-data_socio/2021-11-18_V1/network_employed_V1.csv", ",", int, true));
	matrix<int> network_pensioner <- matrix<int>(csv_file("../includes/csv-data_socio/2021-11-18_V1/network_pensioner_V1.csv", ",", int, true));
	matrix<int> network_selfemployed <- matrix<int>(csv_file("../includes/csv-data_socio/2021-11-18_V1/network_self-employed_V1.csv", ",", int, true));
	matrix<int> network_student <- matrix<int>(csv_file("../includes/csv-data_socio/2021-11-18_V1/network_student_V1.csv", ",", int, true));
	matrix<int> network_unemployed <- matrix<int>(csv_file("../includes/csv-data_socio/2021-11-18_V1/network_unemployed_V1.csv", ",", int, true));
		
	matrix<float> share_income <- matrix<float>(csv_file("../includes/csv-data_socio/2021-11-18_V1/share-income_V1.csv",  ",", float, true)); // share of households in neighborhood sorted by income
	matrix<float> share_employment_income <- matrix<float>(csv_file("../includes/csv-data_socio/2021-11-18_V1/share-employment_income_V1.csv", ",", float, true)); // distribution of employment status of households in neighborhood sorted by income
	matrix<float> share_ownership_income <- matrix<float>(csv_file("../includes/csv-data_socio/2021-11-18_V1/share-ownership_income_V1.csv", ",", float, true)); // distribution of ownership status of households in neighborhood sorted by income
	
	
	matrix<float> share_age_buildings_existing <- matrix<float>(csv_file("../includes/csv-data_socio/2021-11-18_V1/share-age_existing_V2.csv", ",", float, true)); // distribution of groups of age in neighborhood
	matrix<float> average_lor_inclusive <- matrix<float>(csv_file("../includes/csv-data_socio/2021-12-15/wohndauer_nach_alter_inkl_geburtsort.csv", ",", float, true)); //average lenght of residence for different age-groups including people who never moved
	matrix average_lor_exclusive <- matrix(csv_file("../includes/csv-data_socio/2021-12-15/wohndauer_nach_alter_ohne_geburtsort.csv", ",", float, true)); //average lenght of residence for different age-groups ecluding people who never moved


	int nb_units <- get_nb_units(); // number of households in v1
	int global_neighboring_distance <- 2;
	
	float share_families <- 0.17; 
	float share_socialgroup_families <- 0.75; 
	float share_socialgroup_nonfamilies <- 0.29; 
	
	float private_communication <- 0.25; // 
	string influence_type <- "one-side";
	bool communication_memory <- true;
	
	list<species<households>> income_groups_list <- [households_500_1000, households_1000_1500, households_1500_2000, households_2000_3000, households_3000_4000, households_4000etc];
	map<species<households>,float> share_income_map <- create_map(income_groups_list, list(share_income));
	map decision_map <- create_map(income_groups_list, [decision_500_1000, decision_1000_1500, decision_1500_2000, decision_2000_3000, decision_3000_4000, decision_4000etc]);
	
	list<float> shares_owner_list <- [share_ownership_income[1,0], share_ownership_income[2,0], share_ownership_income[3,0], share_ownership_income[4,0], share_ownership_income[5,0], share_ownership_income[6,0]];	
	map<species<households>,float> share_owner_map <- create_map(income_groups_list, shares_owner_list); 


	list<float> shares_student_list <- [share_employment_income[1,0], share_employment_income[2,0], share_employment_income[3,0], share_employment_income[4,0], share_employment_income[5,0], share_employment_income[6,0]];
	list<float> shares_employed_list <- [share_employment_income[1,1], share_employment_income[2,1], share_employment_income[3,1], share_employment_income[4,1], share_employment_income[5,1], share_employment_income[6,1]];
	list<float> shares_selfemployed_list <- [share_employment_income[1,2], share_employment_income[2,2], share_employment_income[3,2], share_employment_income[4,2], share_employment_income[5,2], share_employment_income[6,2]];
	list<float> shares_unemployed_list <- [share_employment_income[1,3], share_employment_income[2,3], share_employment_income[3,3], share_employment_income[4,3], share_employment_income[5,3], share_employment_income[6,3]];
	list<float> shares_pensioner_list <- [share_employment_income[1,4], share_employment_income[2,4], share_employment_income[3,4], share_employment_income[4,4], share_employment_income[5,4], share_employment_income[6,4]];
	
	map<species<households>,float> share_student <- create_map(income_groups_list, shares_student_list);
	map<species<households>,float> share_employed <- create_map(income_groups_list, shares_employed_list);
	map<species<households>,float> share_selfemployed <- create_map(income_groups_list, shares_selfemployed_list);
	map<species<households>,float> share_unemployed <- create_map(income_groups_list, shares_unemployed_list);
	map<species<households>,float> share_pensioner <- create_map(income_groups_list, shares_pensioner_list);
	
	int get_nb_units { //Calculates the number of available units based on the Kataster-data.
		int sum <- 0;
		loop bldg over: shape_file_buildings {
			sum <- sum + int(bldg get "Kataster_W");
		}
		return sum;
	}

	list<list<households>> random_groups(list<households> input, int n) { // Randomly distributes the elements of the input-list in n lists of similar size.
		int len <- length(input);
		if len = 0 {
			return range(n - 1) accumulate [[]];
		}
		else if len = 1 {
			list<list<households>> output <- range(n - 2) accumulate [[]];
			add input to: output;
			return shuffle(output);
		}
		else {
			list shuffled_input <- shuffle(input);
			list inds <- split_in(range(len - 1), n);
			list<list<households>> output;
			loop group over: inds {
				add shuffled_input where (index_of(shuffled_input, each) in group) to: output;
			}
			return shuffle(output);
		}
	
	}
	
	init { 		
		
		
		create building from: shape_file_buildings with: [type:: string(read(attributes_source)), units::int(read("Kataster_W")), street::string(read("Kataster_S")), vacant::bool(int(read("Kataster_W")))] { // create agents according to shapefile metadata
			if type = "EFH" {
				color <- #blue;
			}
			else if type = "MFH" {
				color <- #orange;
			}
			else if type = "NWG" {
				color <- #red;
			}
			else if type = "DHH" {
				color <- #brown;
			}
			else if type = "E-MG" {
				color <- #yellow;
			}
			else if type = "M-MG" {
				color <- #purple;
			}
			else if type = "RH" {
				color <- #green;
			}
			else if type = "SON" {
				color <- #black;
			}
			else if type = "SOZ" {
				color <- #pink;
			}
		}
		
	//	create nahwaermenetz from: nahwaerme;


		loop income_group over: income_groups_list { 
			let letters <- ["a", "b", "c", "d"];
			loop i over: range(0,3) { // 4 subgroups a created for each income_group to represent the distribution of the given variables
				create income_group number: share_income_map[income_group] * nb_units * 0.25 {
					float decision_500_1000_CEEK_min <- decision_map[income_group][1,i];
					float decision_500_1000_CEEK_1st <- decision_map[income_group][1,i+1];
					CEEK <- rnd (decision_500_1000_CEEK_min, decision_500_1000_CEEK_1st);
					float decision_500_1000_CEEA_min <- decision_map[income_group][2,i];
					float decision_500_1000_CEEA_1st <- decision_map[income_group][2,i+1];
					CEEA <- rnd (decision_500_1000_CEEA_min, decision_500_1000_CEEA_1st);
					float decision_500_1000_EDA_min <- decision_map[income_group][3,i];
					float decision_500_1000_EDA_1st <- decision_map[income_group][3,i+1];
					EDA <- rnd (decision_500_1000_EDA_min, decision_500_1000_EDA_1st);
					float decision_500_1000_PN_min <- decision_map[income_group][4,i];
					float decision_500_1000_PN_1st <- decision_map[income_group][4,i+1];
					PN <- rnd (decision_500_1000_PN_min, decision_500_1000_PN_1st);
					float decision_500_1000_SN_min <- decision_map[income_group][5,i];
					float decision_500_1000_SN_1st <- decision_map[income_group][5,i+1];
					SN <- rnd (decision_500_1000_SN_min, decision_500_1000_SN_1st);
					float decision_500_1000_EEH_min <- decision_map[income_group][6,i];
					float decision_500_1000_EEH_1st <- decision_map[income_group][6,i+1];
					EEH <- rnd (decision_500_1000_EEH_min, decision_500_1000_EEH_1st);
					float decision_500_1000_PBC_I_min <- decision_map[income_group][7,i];
					float decision_500_1000_PBC_I_1st <- decision_map[income_group][7,i+1];
					PBC_I <- rnd (decision_500_1000_PBC_I_min, decision_500_1000_PBC_I_1st);
					float decision_500_1000_PBC_C_min <- decision_map[income_group][8,i];
					float decision_500_1000_PBC_C_1st <- decision_map[income_group][8,i+1];
					PBC_C <- rnd (decision_500_1000_PBC_C_min, decision_500_1000_PBC_C_1st);
					float decision_500_1000_PBC_S_min <- decision_map[income_group][9,i];
					float decision_500_1000_PBC_S_1st <- decision_map[income_group][9,i+1];
					PBC_S <- rnd (decision_500_1000_PBC_S_min, decision_500_1000_PBC_S_1st);
					id_group <- string(income_group) + "_" + letters[i]; 			
					
					do find_house; //Locate household in a random building.
				}
			}
		}
		
				
// Age -> distributes the share of age-groups among the generic-species household
	
		ask (int(share_age_buildings_existing[0] * nb_units)) among (agents of_generic_species households where (!bool(each.age))) {
			age <- rnd (21, 40);
			let share_families_21_40 <- ((share_families * nb_units) / (int(share_age_buildings_existing[0] * nb_units))); // calculates share of families in neighborhood for households with age 21-40
			if flip(share_families_21_40) {
				family <- true;
			}	
		}
		ask (int(share_age_buildings_existing[1] * nb_units)) among (agents of_generic_species households where (!bool(each.age))) {
			age <- rnd (41, 60);	
		}
		ask (int(share_age_buildings_existing[2] * nb_units)) among (agents of_generic_species households where (!bool(each.age))) {
			age <- rnd (61, 80);	
		}
		ask (int(share_age_buildings_existing[3] * nb_units)) among (agents of_generic_species households where (!bool(each.age))) {
			age <- rnd (81, 100); //max age = 100	
		}
		
		
// Ownership 
	
		loop income_group over: income_groups_list {
			ask income_group {
				ownership <- "tenant";
			}
			
			ask int(share_owner_map[income_group] * length(income_group)) among income_group { 
				ownership <- "owner";
			}
		}
		
	
// Employment

		loop income_group over: income_groups_list {
			ask round(share_student[income_group] * length(income_group)) among income_group{
				employment <- "student";
			}
			ask round(share_selfemployed[income_group] * length(income_group)) among income_group where (each.employment = nil) {
				employment <- "self_employed";
			}
			ask round(share_unemployed[income_group] * length(income_group)) among income_group where (each.employment = nil) {
				employment <- "unemployed";
			}
			ask round(share_pensioner[income_group] * length(income_group)) among income_group where (each.employment = nil) {
				employment <- "pensioner";
			}
			ask income_group where (each.employment = nil) { // all remaining households are assinged to 'employed'
				employment <- "employed";
			}

		}
		
		

		
//Network -> distributes the share of network-relations among the households. there are different network values for each employment status
		list<string> employment_status_list  <- ["student", "employed", "self-employed", "unemployed", "pensioner"]; 

		map<string,matrix<float>> network_map <- create_map(employment_status_list, [network_student, network_employed, network_selfemployed, network_unemployed, network_pensioner]);
		list<string> temporal_network_attributes <- households.attributes where (each contains "network_contacts_temporal"); // list of all temporal network variables
		list<string>  spatial_network_attributes <- households.attributes where (each contains "network_contacts_spatial"); // list of all spatial network variables
		loop emp_status over: employment_status_list { //iterate over the different employment states
			list<households> tmp_households <- (agents of_generic_species households) where (each.employment = emp_status); //temporary list of households with the current employment status
			int nb <- length(tmp_households); 
			matrix<float> network_matrix <- network_map[emp_status]; //corresponding matrix of network values
			loop attr over: temporal_network_attributes { //loop over the different temporal network variables of each household
				int index <- index_of(temporal_network_attributes, attr);
				list tmp_households_grouped  <- random_groups(tmp_households, 4);
				loop i over: range(0, 3) { // loop to split the households in 4 quartiles
					ask tmp_households_grouped[i] {
						self[attr] <- rnd(network_matrix[index+2, i],network_matrix[index+2, i+1]);
					}
				}
			}
			loop attr over: spatial_network_attributes { // loop over the different spatial network variables of each household
				int index <- index_of(spatial_network_attributes, attr);
				list<list<households>>  tmp_households_grouped  <- random_groups(tmp_households, 4);
				loop i over: range(0, 3) {// loop to split the households in 4 quarters
					ask tmp_households_grouped[i] {
						self[attr] <- rnd(network_matrix[index+6, i],network_matrix[index+6, i+1]);
					}
				}
			}
		}
		
		ask agents of_generic_species households where (bool(each.family)) { //distributes belonging to socialgroups over non-/families

			if flip (share_socialgroup_families) {
				network_socialgroup <- true;
			}	
		}
		ask agents of_generic_species households where (!each.family) {
			if flip (share_socialgroup_nonfamilies) {
				network_socialgroup <- true;	
			}	
		}
		
		//TODO
		ask agents of_generic_species households { //creates network of social contacts
			do get_social_contacts; 
			network <- network add_node(self);
		}
		
			loop edges_from over: agents of_generic_species households {
				loop edges_to over: edges_from.social_contacts {
					if !(contains_edge(network, edges_from::edges_to)) {
						network <- network add_edge(edges_from::edges_to);						
					}
				}
			}
		
	}

					

	reflex new_household { //creates new households to keep the total number of households constant.
		let new_households of: households <- [];
		let n <- length(agents of_generic_species households);
		let wheights <- list(share_income);
		remove 1.0 from: wheights;
		let employment_status_list of: string <- ["student", "employed", "self-employed", "unemployed", "pensioner"];
		loop while: n < nb_units {
			let income_group<- sample(income_groups_list, 1, false, wheights)[0];
			let i <- rnd(0,3);
			create income_group number: 1 {
				add self to: new_households;
				do find_house;
				age <- rnd(21, 40);
				let share_families_21_40 <- ((share_families * nb_units) / (int(share_age_buildings_existing[0] * nb_units)));
				family <- flip(share_families_21_40);
				float decision_500_1000_CEEK_min <- decision_map[income_group][1,i];
				float decision_500_1000_CEEK_1st <- decision_map[income_group][1,i+1];
				CEEK <- rnd (decision_500_1000_CEEK_min, decision_500_1000_CEEK_1st);
				float decision_500_1000_CEEA_min <- decision_map[income_group][2,i];
				float decision_500_1000_CEEA_1st <- decision_map[income_group][2,i+1];
				CEEA <- rnd (decision_500_1000_CEEA_min, decision_500_1000_CEEA_1st);
				float decision_500_1000_EDA_min <- decision_map[income_group][3,i];
				float decision_500_1000_EDA_1st <- decision_map[income_group][3,i+1];
				EDA <- rnd (decision_500_1000_EDA_min, decision_500_1000_EDA_1st);
				float decision_500_1000_PN_min <- decision_map[income_group][4,i];
				float decision_500_1000_PN_1st <- decision_map[income_group][4,i+1];
				PN <- rnd (decision_500_1000_PN_min, decision_500_1000_PN_1st);
				float decision_500_1000_SN_min <- decision_map[income_group][5,i];
				float decision_500_1000_SN_1st <- decision_map[income_group][5,i+1];
				SN <- rnd (decision_500_1000_SN_min, decision_500_1000_SN_1st);
				float decision_500_1000_EEH_min <- decision_map[income_group][6,i];
				float decision_500_1000_EEH_1st <- decision_map[income_group][6,i+1];
				EEH <- rnd (decision_500_1000_EEH_min, decision_500_1000_EEH_1st);
				float decision_500_1000_PBC_I_min <- decision_map[income_group][7,i];
				float decision_500_1000_PBC_I_1st <- decision_map[income_group][7,i+1];
				PBC_I <- rnd (decision_500_1000_PBC_I_min, decision_500_1000_PBC_I_1st);
				float decision_500_1000_PBC_C_min <- decision_map[income_group][8,i];
				float decision_500_1000_PBC_C_1st <- decision_map[income_group][8,i+1];
				PBC_C <- rnd (decision_500_1000_PBC_C_min, decision_500_1000_PBC_C_1st);
				float decision_500_1000_PBC_S_min <- decision_map[income_group][9,i];
				float decision_500_1000_PBC_S_1st <- decision_map[income_group][9,i+1];
				PBC_S <- rnd (decision_500_1000_PBC_S_min, decision_500_1000_PBC_S_1st);
				id_group <- string(income_group) + "_" + ["a", "b", "c", "d"][i];
				employment <- sample(employment_status_list, 1, false)[0];
				if flip(share_owner_map[income_group]) {
					ownership <- "owner";
				}
				else {
					ownership <- "tenant";
				}
				
			}
			n <- n + 1;
		}
 		// Distribute network values among the new households
		map<string, matrix<float>> network_map <- create_map(employment_status_list, [network_student, network_employed, network_selfemployed, network_unemployed, network_pensioner]);
		list<string> temporal_network_attributes <- households.attributes where (each contains "network_contacts_temporal"); // list of all temporal network variables
		list<string> spatial_network_attributes <- households.attributes where (each contains "network_contacts_spatial"); // list of all spatial network variables
		loop emp_status over: employment_status_list { //iterate over the different employment states
			let tmp_households <- new_households of_generic_species households where (each.employment = emp_status); //temporary list of households with the current employment status
			let nb <- length(tmp_households); 
			//write [nb, 0.25 * nb];
			matrix<float> network_matrix <- network_map[emp_status]; //corresponding matrix of network values
			loop attr over: temporal_network_attributes { //loop over the different temporal network variables of each household
				let index <- index_of(temporal_network_attributes, attr);
				let tmp_households_grouped type: list <- random_groups(tmp_households, 4);
				loop i over: range(0, 3) { // loop to split the households in 4 quartiles
					ask (tmp_households_grouped[i]) {
						//write self.name;
						self[attr] <- rnd(network_matrix[index+2, i],network_matrix[index+2, i+1]);
					}
				}
			}
			loop attr over: spatial_network_attributes { // loop over the different spatial network variables of each household
				int index <- index_of(spatial_network_attributes, attr);
				list tmp_households_grouped <- random_groups(tmp_households, 4);
				loop i over: range(0, 3) {// loop to split the households in 4 quarters
					ask tmp_households_grouped[i] {
						self[attr] <- rnd(network_matrix[index+6, i],network_matrix[index+6, i+1]);
					}
				}
			}
		}
		
		ask new_households of_generic_species households where (bool(each.family)) {
			if flip (share_socialgroup_families) {
				network_socialgroup <- true;
			}	
		}
		ask new_households of_generic_species households where (!bool(each.family)) {
			if flip (share_socialgroup_nonfamilies) {
				network_socialgroup <- true;
			}	
		}
		
		ask new_households of_generic_species households {
			do get_social_contacts;
			network <- network add_node(self);
			loop edges_to over: self.social_contacts {
					
					if !(contains_edge(network, self::edges_to)){
						network <- network add_edge(self::edges_to);						
					}
			}
		}
		if sum_of(new_households of_generic_species households, length(each.social_contacts)) > 0 { 
		}
	
	}
}
		
species building {
	string type;
	int units;
	int tenants <- 0;
	bool vacant <- true;
	string street;
	
	rgb color <- #gray;
	geometry line;
	
	action add_tenant {
		self.tenants <- self.tenants + 1;
		if self.tenants = self.units {
			self.vacant <- false;
		}
		return any_location_in(self);
	}
	action remove_tenant {
		self.tenants <- self.tenants - 1;
		self.vacant <- true;
	
	}
	
	list get_neighboring_households { // returns a list of all households living in the n closest buildings, where n is defined by the parameter 'global_neighboring_distance'.
		list neighbors;
		ask closest_to(building, self, global_neighboring_distance) {
			neighbors <- self.get_tenants() + neighbors;
		}
		return neighbors;
	}
	
	list get_tenants { // returns a list of all households that are living in the building.
		return inside(agents of_generic_species(households), self);
	}
	
	aspect base {
		draw shape color: color;
	}
}


//species nahwaermenetz{
	
//	rgb color <- #gray;
//	aspect base{
//		draw shape color: color;
//	}
//}


species households {
	float CEEK; // Climate-Energy-Environment Knowledge
	float CEEA; // Climate-Energy-Environment Awareness
	float EDA; // Energy-Related-Decision Awareness
	float KA; // ---Decision-Threshold---: Knowledge & Awareness
	float PN; // Personal Norms
	float SN; // Subjective Norms
	float PSN; // ---Decicision-Threshold---: Personal & Subjective Norms
	float PBC_I; // Perceived-Behavioral-Control Invest
	float PBC_C; // Perceived-Behavioral-Control Change
	float PBC_S; // Perceived-Behavioral-Control Switch	
	float PBC_I_7; // Perceived-Behavioral-Control Invest divided by 7
	float PBC_C_7; // Perceived-Behavioral-Control Change divided by 7
	float PBC_S_7; // Perceived-Behavioral-Control Switch divided by 7	
	float N_PBC_I; // ---Decicision-Threshold---: Normative Perceived Behavioral Control Invest
	float N_PBC_C; // ---Decicision-Threshold---: Normative Perceived Behavioral Control Change
	float N_PBC_S; // ---Decicision-Threshold---: Normative Perceived Behavioral Control Switch
	float EEH; // Energy Efficient Habits
	
	
	
	int income; // households income/month -> ATTENTION -> besonderer Validierungshinweis, da zufaellige Menge
	string id_group; // identification which quartile within the income group the agent belongs to
		
	int age; // random mean-age of households
	int lenght_of_residence <- 0; //years since the household moved in
	string ownership; // type of ownership status of households
	string employment; // employment status of households !!!
		


	// defines network behavior of each agent in parent species by employment status
	int network_contacts_temporal_daily <- -99; // amount of agents a household has daily contact with - 30x / month
	int network_contacts_temporal_weekly; // amount of agents a household has weekly contact with - 4x / month
	int network_contacts_temporal_occasional; // amount of agents a household has occasional contact with - 1x / month
	int network_contacts_spatial_direct; // available amount of contacts within an households network - direct neighbors
	int network_contacts_spatial_street; // available amount of contacts within an households network - contacts in the same street
	int network_contacts_spatial_neighborhood; // available amount of contacts within an households network - contacts in the same neighborhood
	int network_contacts_spatial_beyond; // available amount of contacts within an households network - contacts beyond the system's environment TODO

	bool family; // represents young families - higher possibility of being part of a socialgroup
	bool network_socialgroup; // households are part of a social group - accelerates the networking behavior
	
	building house; 
	
	
	list<households> social_contacts_direct;
	list<households> social_contacts_street;
	list<households> social_contacts_neighborhood;
	list<households> social_contacts;


	action find_house {
		self.house <- any (building where (each.vacant));
		self.location <- self.house.add_tenant();

	}

	action get_social_contacts { 
		social_contacts_direct <- self.network_contacts_spatial_direct among (self.house.get_neighboring_households() + self.house.get_tenants() - self);
		social_contacts_street <- self.network_contacts_spatial_street among agents of_generic_species households where(each.house.street = self.house.street);
		social_contacts_neighborhood <- self.network_contacts_spatial_neighborhood among agents of_generic_species households where(each.house.street != self.house.street);
		social_contacts <- remove_duplicates(social_contacts_direct + social_contacts_street + social_contacts_neighborhood);
	}
	
	action update_social_contacts(agent old_contact) { //removes the 'old_contact' from the households list of contacts and adds a new random contact.
		
		if (old_contact in self.social_contacts_direct) {
			remove old_contact from: self.social_contacts_direct;
			social_contacts_direct <- social_contacts_direct + (1 among ((agents of_generic_species households) at_distance(global_neighboring_distance)));
		}
		if (old_contact in self.social_contacts_street) {
			remove old_contact from: self.social_contacts_street;
			social_contacts_street <- social_contacts_street + (1 among agents of_generic_species households where(each.employment = self.employment));
		}
		if (old_contact in self.social_contacts_neighborhood) {
			remove old_contact from: self.social_contacts_neighborhood;
			social_contacts_neighborhood <- social_contacts_neighborhood + (1 among agents of_generic_species households where(each.employment = self.employment));
		}
		let new_social_contacts <- remove_duplicates(social_contacts_direct + social_contacts_street + social_contacts_neighborhood) - social_contacts;
		social_contacts <- remove_duplicates(social_contacts_direct + social_contacts_street + social_contacts_neighborhood);
		loop node over: new_social_contacts {
			network <- network add_edge(self::node);
		}
	}

	

	
	
	reflex communicate_daily { //TODO Validiere kurz Unterschied auf Werte bei (1) einseitigem Einfluss (2) gegenseitigem Einfluss; Erweiterung: (3) Einmalige Kommunikation zweier Kontakte
		
		if network_contacts_temporal_daily > 0 {
			ask network_contacts_temporal_daily among social_contacts { //TODO Soll fuer jede Variable eine andere Gruppe von Kontakten ausgewaehlt werden? 
        		let current_edge <- edge_between(network, self::myself);
        		let flag <- false;
        		if communication_memory {
        			if weight_of(network, current_edge) != cycle{
        				network <- with_weights(network, [current_edge::cycle]);
        				flag <- true;
        				create edge_vis number: 1 with: (my_edge:current_edge);
        			}
        		}
        		else {
        			flag <- true;
        			create edge_vis number: 1 with: (my_edge:current_edge);
        		}
        		if flag {
	        		if (self.CEEA < mean([myself.CEEA, self.CEEA])) and self.CEEA < 7 {
	        			self.CEEA <- self.CEEA + private_communication;
	        			if influence_type = "both_sides"{
	        				myself.CEEA <- myself.CEEA - private_communication;// validierung - wie kann hier ein nachvollziehbarer wert gewaehlt werden? Oder muss dies Teil der Untersuchtung sein? & wieso - unendlich?
	        			}
	        		}
	        		else if CEEA > 0 {
	        			self.CEEA <- self.CEEA - private_communication;
	        			if influence_type = "both_sides"{
	        				myself.CEEA <- myself.CEEA + private_communication;
	        			}
	        		}
	        		
	        		if (self.EDA < mean([myself.EDA, self.EDA])) and self.EDA < 7 {
	        			self.EDA <- self.EDA + private_communication;
	        			if influence_type = "both_sides"{
	        				myself.EDA <- myself.EDA - private_communication;
	        			}
	        		}
	        		else if EDA > 0 {
	        			self.EDA <- self.EDA - private_communication;
	        			if influence_type = "both_sides"{
	        				myself.EDA <- myself.EDA + private_communication;
	        			}
	        		}
	        		
	        		if (self.SN < mean([myself.SN, self.SN])) and self.SN < 7 {
	        			self.SN <- self.SN + private_communication;
	        			if influence_type = "both_sides"{
	        				myself.SN <- myself.SN - private_communication;
	        			}
	        		}
	        		else if SN > 0 {
	        			self.SN <- self.SN - private_communication;
	        			if influence_type = "both_sides"{
	        				myself.SN <- myself.SN + private_communication;
	        			}
	        		}
        		
        		}
        		
        	}
				
        }
	}
	
	reflex communicate_weekly { // includes communication with social groups -> increasing factor
		if network_contacts_temporal_weekly > 0 {
			if cycle mod 7 = 0 { 
				ask network_contacts_temporal_weekly among social_contacts {
        			let flag <- false;
        			let current_edge <- edge_between(network, self::myself);
	        		if communication_memory {        			
	        			if weight_of(network, current_edge) != cycle{
	        				network <- with_weights(network, [current_edge::cycle]);
	        				flag <- true;
	        				create edge_vis number: 1 with: (my_edge:current_edge);
	        			}
	        		}
        			else {
        				flag <- true;
        				create edge_vis number: 1 with: (my_edge:current_edge);
        			}
        			if flag {
	        			if self.network_socialgroup = true and ((self.CEEA < mean([myself.CEEA, self.CEEA])) and self.CEEA < 7) {
	        				self.CEEA <- self.CEEA + (private_communication * 2);
	        				if influence_type = "both_sides"{
	        					myself.CEEA <- myself.CEEA - (private_communication * 2);
	        				} 
	        			}
	        			else if self.network_socialgroup = true and self.CEEA > 0 {
	        				self.CEEA <- self.CEEA - (private_communication * 2);
	        				if influence_type = "both_sides"{
	        					myself.CEEA <- myself.CEEA + (private_communication * 2);
	        				} 
	      			  	}
	      			  	else if self.network_socialgroup = false and ((self.CEEA < mean([myself.CEEA, self.CEEA])) and self.CEEA < 7) {
	        				self.CEEA <- self.CEEA + private_communication;
	        				if influence_type = "both_sides"{
	        					myself.CEEA <- myself.CEEA - private_communication;
	        				}  
	        			}
	        			else if self.network_socialgroup = false and self.CEEA > 0 {
	        				self.CEEA <- self.CEEA - private_communication;
	        				if influence_type = "both_sides"{
	        					myself.CEEA <- myself.CEEA + private_communication;
	        				}
	      			  	}
	      			  	
	      			
        		
	        			if self.network_socialgroup = true and ((self.EDA < mean([myself.EDA, self.EDA])) and self.EDA < 7) {
	        				self.EDA <- self.EDA + (private_communication * 2);
	        				if influence_type = "both_sides"{
	        					myself.EDA <- myself.EDA - (private_communication * 2);
	        				} 
	        			}
	        			else if self.network_socialgroup = true and self.EDA > 0 {
	        				self.EDA <- self.EDA - (private_communication * 2);
	        				if influence_type = "both_sides"{
	        					myself.EDA <- myself.EDA + (private_communication * 2);
	        				} 
	      			  	}
	      			  	else if self.network_socialgroup = false and ((self.EDA < mean([myself.EDA, self.EDA])) and self.EDA < 7) {
	        				self.EDA <- self.EDA + private_communication;
	        				if influence_type = "both_sides"{
	        					myself.EDA <- myself.EDA - private_communication;
	        				}  
	        			}
	        			else if self.network_socialgroup = false and self.EDA > 0 {
	        				self.EDA <- self.EDA - private_communication;
	        				if influence_type = "both_sides"{
	        					myself.EDA <- myself.EDA + private_communication;
	        				}
	      			  	}
	      			
	        			if (self.SN < mean([myself.SN, self.SN])) and self.SN < 7 {
	        				self.SN <- self.SN + private_communication;
	        				if influence_type = "both_sides"{
	        					myself.SN <- myself.SN - private_communication;
	        				} 
	        			}
	        			else if SN > 0 {
	        				self.SN <- self.SN - private_communication;
	        				if influence_type = "both_sides"{
	        					myself.SN <- myself.SN + private_communication;
	        				}
	        			}
	        			
	        		}
        		}
        	}
        }
	}
	
	reflex communicate_occasional { 
		if network_contacts_temporal_occasional > 0 {
			if cycle mod 30 = 0 { 
				ask network_contacts_temporal_occasional among social_contacts {
       		 		let flag <- false;
       		 		let current_edge <- edge_between(network, self::myself);
	        		if communication_memory {
	        			if weight_of(network, current_edge) != cycle{
	        				network <- with_weights(network, [current_edge::cycle]);
	        				flag <- true;
	        				create edge_vis number: 1 with: (my_edge:current_edge);
	        			}
	        		}
	        		else {
	        			flag <- true;
	        			create edge_vis number: 1 with: (my_edge:current_edge);
	        		}
	        		if flag {
		        		if (self.CEEA < mean([myself.CEEA, self.CEEA])) and self.CEEA < 7 {
		        			self.CEEA <- self.CEEA + private_communication;
		        			if influence_type = "both_sides"{
		        				myself.CEEA <- myself.CEEA - private_communication;// validierung - wie kann hier ein nachvollziehbarer wert gewaehlt werden? Oder muss dies Teil der Untersuchtung sein? & wieso - unendlich?
		        			}
		        		}
		        		else if CEEA > 0 {
		        			self.CEEA <- self.CEEA - private_communication;
		        			if influence_type = "both_sides"{
		        				myself.CEEA <- myself.CEEA + private_communication;
		        			}
		        		}
		        		
		        		if (self.EDA < mean([myself.EDA, self.EDA])) and self.EDA < 7 {
		        			self.EDA <- self.EDA + private_communication;
		        			if influence_type = "both_sides"{
		        				myself.EDA <- myself.EDA - private_communication;
		        			}
		        		}
		        		else if EDA > 0 {
		        			self.EDA <- self.EDA - private_communication;
		        			if influence_type = "both_sides"{
		        				myself.EDA <- myself.EDA + private_communication;
		        			}
		        		}
		        		
		        		if (self.SN < mean([myself.SN, self.SN])) and self.SN < 7 {
		        			self.SN <- self.SN + private_communication;
		        			if influence_type = "both_sides"{
		        				myself.SN <- myself.SN - private_communication;
		        			}
		        		}
		        		else if SN > 0 {
		        			self.SN <- self.SN - private_communication;
		        			if influence_type = "both_sides"{
		        				myself.SN <- myself.SN + private_communication;
		        			}
		        		}
	        		
	        		}
        		
        		}
        	}
        }
	}
	
	
	
	action update_decision_thresholds {
		/* calculate household's current 
		knowledge & awareness (0 <= KA <= 1),
		personal & subjective norms (0 <= PSN <= 1) and
		perceived behavioral control (0 <= N_PBC <= 1) */ 
		KA <- mean(CEEK, CEEA, EDA) / 7;
		PSN <- mean(PN, SN) / 7;
		PBC_I_7 <- mean(PBC_I) / 7;
		PBC_C_7 <- mean(PBC_C) / 7;
		PBC_S_7 <- mean(PBC_S) / 7;
	}
	
	action update_decision_thresholds_subjectivenorm { // gives subjective norms a higher weight in an agent's decision making process
		/* calculate household's current 
		knowledge & awareness (0 <= KA <= 1),
		personal & subjective norms (0 <= PSN <= 1) and
		normative perceived behavioral control (0 <= N_PBC <= 1) */ 
		KA <- mean(CEEK, CEEA, EDA, SN) / 7;
		PSN <- mean(PN, SN) / 7;
		N_PBC_I <- mean(PBC_I, SN) / 7;
		N_PBC_C <- mean(PBC_C, SN) / 7;
		N_PBC_S <- mean(PBC_S, SN) / 7;
	}
	
	
	
	reflex move_out {
		if cycle mod 365 = 0 {
			age <- age + 1;
			lenght_of_residence <- lenght_of_residence + 1;
			let current_agent <- self;
			if age >= 100 {
				ask households(neighbors_of(network, self)) {
					do update_social_contacts(current_agent);
				}
				remove self from: network;
				ask self.house{
					do remove_tenant;
				}
				do die;
				
			}
			int current_age_group <- int(floor(age / 20)) - 1; // age-groups are represented with integers. Each group spans 20 years with 0 => [20,39], 1 => [40,59] ...
			float moving_prob  <- 1 / average_lor_inclusive[1, current_age_group];
			if flip(moving_prob) {
				households hs <- households(neighbors_of(network, self));
				if hs != nil {
					ask hs {
						do update_social_contacts(current_agent);
					}
				}
				remove self from: network;
				ask self.house {
					do remove_tenant;
				}
				do die;
				
			}
			
		}
		
	}
	
	reflex retire { //emp-status of the household moves to "pensioner" when they reach age 64.
		if (self.age >= 64) and (self.employment != "pensioner") {
			self.employment <- "pensioner";
		}
	}
	

} 


species households_500_1000 parent: households {
	
	aspect base {
		draw circle(1) color: #green; // test-darstellung
	}
	
	int income <- rnd(500, 1000);
	
	
}

species households_1000_1500 parent: households {
	
	aspect base {
		draw circle(1) color: #red; // test-darstellung
	}

	int income <- rnd(1000, 1500);
	
	
}

species households_1500_2000 parent: households {
	
	aspect base {
		draw circle(1) color: #blue; // test-darstellung
	}

	int income <- rnd(1500, 2000);

	
}

species households_2000_3000 parent: households {
	
	aspect base {
		draw circle(1) color: #yellow; // test-darstellung
	}

	int income <- rnd(2000, 3000);

	
}

species households_3000_4000 parent: households {
	
	aspect base {
		draw circle(1) color: #purple; // test-darstellung
	}
	
	int income <- rnd(3000, 4000);
	
	
}

species households_4000etc parent: households {
	
	aspect base {
		draw circle(1) color: #grey; // test-darstellung
	}
	
	int income <- rnd(4000, 10000); // max income / month = 10.000
	
	
}

species edge_vis {
	pair my_edge;
	int age <- 0;
	
	reflex disappear {
		if self.age = 0 {
			self.age <- self.age + 1;
		}
		else {
			do die;
		}
	}
	
	aspect base {
		draw geometry(my_edge) color: #green;
	}
}


	// grid vegetation_cell width: 50 height: 50 neighbors: 4 {} -> Bei derzeitiger Vorstellung wird kein grid benoetigt; ggf mit qScope-Tisch-dev abgleichen

experiment agent_decision_making type: gui{
	

 	parameter "Influence of private communication" var: private_communication min: 0.0 max: 1.0 category: "decision making"; 	
 	parameter "Neighboring distance" var: global_neighboring_distance min: 0 max: 5 category: "communication";
 	parameter "shapefile for buildings:" var: shape_file_buildings category: "GIS";
 	parameter "building types source" var: attributes_source among: attributes_possible_sources category: "GIS";
  	parameter "Influence-Type" var: influence_type among: ["one-side", "both_sides"] category: "Communication";	
	parameter "Memory" var: communication_memory among: [true, false] category: "Communication";
	
	output {
		monitor date value: current_date refresh: every(1#cycle);		
		
		
		layout #split;
		display neighborhood {
		//	image background_map;
//			graphics "network_edges" {
//				loop e over: network.edges {
//					draw geometry(e) color: #black;
//				}
//			}			
			
			species building aspect: base;
		//	species nahwaermenetz aspect: base;
			
			species households_500_1000 aspect: base;
			species households_1000_1500 aspect: base;
			species households_1500_2000 aspect: base;
			species households_2000_3000 aspect: base;
			species households_3000_4000 aspect: base;
			species households_4000etc aspect: base;
			species edge_vis aspect: base;
			
			
	
		}			
	
		display "households_income_bar" {
			chart "households_income" type: histogram {
				data "households_500-1000" value: length (households_500_1000) color:#darkblue;
				data "households_1000-1500" value: length (households_1000_1500) color:#darkcyan;
				data "households_1500-2000" value: length (households_1500_2000) color:#darkgoldenrod;
				data "households_2000-3000" value: length (households_2000_3000) color:#darkgray;
				data "households_3000-4000" value: length (households_3000_4000) color:#darkgreen;
				data "households_>4000" value: length (households_4000etc) color:#darkkhaki;
				data "total" value: sum (length (households_500_1000), length (households_1000_1500),length (households_1500_2000), length (households_2000_3000), length (households_3000_4000), length (households_4000etc)) color:#darkmagenta;
			}
		}
		
		display "households_employment_pie" type: java2D {
			chart "households_employment" type: pie {
				data "student" value: length (agents of_generic_species households where (each.employment = "student")) color: #lightblue;
				data "employed" value: length (agents of_generic_species households where (each.employment = "employed")) color: #lightcoral;
				data "self_employed" value: length (agents of_generic_species households where (each.employment = "self_employed")) color: #lightcyan;
				data "un_employed" value: length (agents of_generic_species households where (each.employment = "un_employed")) color: #lightgoldenrodyellow;
				data "pensioner" value: length (agents of_generic_species households where (each.employment = "pensioner")) color: #lightgray;
			}
		}
		
		display "Charts" {
			chart "Average of decision-variables" type: series {
				data "CEEA" value: sum_of(agents of_generic_species households, each.CEEA) / length(agents of_generic_species households);
				data "EDA" value: sum_of(agents of_generic_species households, each.EDA) / length(agents of_generic_species households);
				data "SN" value: sum_of(agents of_generic_species households, each.SN) / length(agents of_generic_species households);
			}
		}
	}
}

