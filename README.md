# q100_abm
Agent-Based-Modeled Behavior Transformation in QUARREE100

## Recommended folder structure

```
project qScope
└───cspy
│   └───CityScoPy LEGO Decoder
└───data
│       contains LINKS to GIS data from Seafile and api.json for SOFTWARE COMMUNICATION
└───q100_abm
│   │   GAMA workspace folder
│   └───Project_RuesdorferKamp_Network
│   │   │   Project 1: Social Agents Communication Network
│   │	└───RuesdorferKamp_Network_Model-01.gaml
│   └───Project_RuesdorferKamp_Restoration
│    	└───Restoration_Model_01.gaml
└───q100_info
│       infoscreen (JavaScript)
└───q100_viz
│       projection (Python)
└───settings
        initial setup data to initialize ALL SOFTWARE COMPONENTS centrally

```
where:
- cspy: https://github.com/dunland/cspy
- data: has to be linked from server
- GAMA: https://github.com/quarree100/q100_abm
- q100_info: https://github.com/cqx931/q100_info
- q100_viz: https://github.com/dunland/q100_viz
- settings: t.b.a (currently from cspy/settings)


## using GAMA with GitHub

- keep your GAMA workspace folder local, outside of this repository!
- a new project only needs a `.project` file indicating the name of the model, next to the folders `models` and `includes`
- a project's`includes` folder should be stored elsewhere **locally**, contain the same data as stored in Seafile. **Create a symlink to point to a local copy of the `includes` folder**!