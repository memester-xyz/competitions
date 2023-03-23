#!/usr/bin/env bash

forge inspect LensCompetitionHub abi > ../frontend/src/assets/abi/LensCompetitionHub.json

forge inspect Events abi > ../frontend/src/assets/abi/LensCompetitionHubEvents.json

forge inspect BaseCompetitionV1 abi > ../frontend/src/assets/abi/BaseCompetitionV1.json

forge inspect JudgeCompetition abi > ../frontend/src/assets/abi/JudgeCompetition.json

forge inspect JudgeCompetitionMultipleWinners abi > ../frontend/src/assets/abi/JudgeCompetitionMultipleWinners.json
