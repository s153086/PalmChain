import {
  SET_TOKENS_SUBMITTED,
  SET_CURRENT_PLANTATION,
  SET_PLANTATION_INFORMATION
} from "./types";

import { consortiumDeployer } from "../../utils/contractDeploymentInstance";
import { plantationInstance } from "../../utils/plantationInstance";
import { mapToPlantation, isZeroAddress } from "../../utils/mappings";

export const setTokensSubmittedFromPlantation = tokens => {
  return {
    type: SET_TOKENS_SUBMITTED,
    tokens: tokens
  };
};

export const setSelectedPlantation = plantationAddress => {
  return {
    type: SET_CURRENT_PLANTATION,
    plantationAddress: plantationAddress
  };
};

export const setPlantationProperties = plantationProperties => {
  return {
    type: SET_PLANTATION_INFORMATION,
    plantationProperties: plantationProperties
  };
};

//fetch tokens submitted by this plantation
export const fetchTokensSubmitted = address => {
  return async dispatch => {};
};

//Fetch plantation address belonging to currently signed in user (if he is owner of a plantation)
export const identifyPlantationAddressByOwner = (
  userAddress,
  deployerAddress
) => {
  return async dispatch => {
    let deployer = consortiumDeployer(deployerAddress);
    if (deployer === undefined) {
      return;
    }

    let plantationAddress = await deployer.methods
      .plantationOwnerRelation(userAddress)
      .call({
        from: userAddress
      });

    if (isZeroAddress(plantationAddress)) {
      return;
    }
    let plantation = plantationInstance(plantationAddress);

    let information = await plantation.methods.getPlantationInformation().call({
      from: userAddress
    });
    information["address"] = plantationAddress;

    information = mapToPlantation(information);

    dispatch(setPlantationProperties(information));
    dispatch(setSelectedPlantation(plantationAddress));
  };
};

//Fetch whether plantation is approved or pending approvel / has not sent approval request.
export const fetchPlantationInformation = (plantationAddress, userAddress) => {
  return async dispatch => {
    let plantation = plantationInstance(plantationAddress);
    let information = await plantation.methods.getPlantationInformation().call({
      from: userAddress
    });
    information["address"] = plantationAddress;

    information = mapToPlantation(information);

    dispatch(setPlantationProperties(information));
  };
};

//Submit ffb token from selected user address
export const submitFFBToken = (token, userAddress) => {
  return async dispatch => {};
};

export const requestConsortiumApproval = (plantationAddress, userAddress) => {
  return async dispatch => {
    let plantation = plantationInstance(plantationAddress);
    plantation.methods.requestPlantationSubscription().send({
      from: userAddress,
      gas: 4712388,
      gasPrice: 100000000000
    });

    dispatch(fetchPlantationInformation(plantationAddress));
  };
};
