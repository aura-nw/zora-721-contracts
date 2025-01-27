#!/bin/bash

RED_COLOR='\033[0;31m'
GREEN_COLOR='\033[0;32m'
NO_COLOR='\033[0m'

if [ "$RPC_URL" = "" ]; then echo -e "${RED_COLOR}- Missing RPC_URL env variable"; return 1; fi
if [ "$WALLET_ADDRESS" = "" ]; then echo -e "${RED_COLOR}- Missing WALLET_ADDRESS env variable"; return 1; fi
if [ "$PRIVATE_KEY" = "" ]; then echo -e "${RED_COLOR}- Missing PRIVATE_KEY env variable"; return 1; fi
if [ "$VERIFIER_URL" = "" ]; then echo -e "${RED_COLOR}- Missing VERIFIER_URL env variable"; return 1; fi
if [ "$PROTOCOL_REWARD_ADDR" = "" ]; then echo -e "${RED_COLOR}- Missing PROTOCOL_REWARD_ADDR env variable"; return 1; fi

# ====

if [ "$EDITION_METADATA_RENDERER_ADDR" = "" ]
then
  echo "Deploy EditionMetadataRenderer..."
  EDITION_METADATA_RENDERER_DEPLOY_OUTPUT=$(forge create --rpc-url $RPC_URL --private-key $PRIVATE_KEY EditionMetadataRenderer \
    --verify --verifier sourcify --verifier-url $VERIFIER_URL)
  EDITION_METADATA_RENDERER_ADDR=$(echo ${EDITION_METADATA_RENDERER_DEPLOY_OUTPUT#*"Deployed to: "} | head -c 42)
  echo -e "${GREEN_COLOR}- deployed to: $EDITION_METADATA_RENDERER_ADDR"

  if [[ $EDITION_METADATA_RENDERER_DEPLOY_OUTPUT == *"Contract successfully verified"* ]]; then
    echo -e "${GREEN_COLOR}- verification result: success"
  else
    echo -e "${RED_COLOR}- fail to verify contract $EDITION_METADATA_RENDERER_ADDR"
    echo "$EDITION_METADATA_RENDERER_DEPLOY_OUTPUT"
  fi
else
  echo "Skip deploying EditionMetadataRenderer. Contract address provided ($EDITION_METADATA_RENDERER_ADDR)"
fi
# ====

if [ "$DROP_METADATA_RENDERER_ADDR" = "" ]
then
  echo -e "${NO_COLOR}Deploy DropMetadataRenderer..."
  DROP_METADATA_RENDERER_DEPLOY_OUTPUT=$(forge create --rpc-url $RPC_URL --private-key $PRIVATE_KEY DropMetadataRenderer \
    --verify --verifier sourcify --verifier-url $VERIFIER_URL)
  DROP_METADATA_RENDERER_ADDR=$(echo ${DROP_METADATA_RENDERER_DEPLOY_OUTPUT#*"Deployed to: "} | head -c 42)
  echo -e "${GREEN_COLOR}- deployed to: $DROP_METADATA_RENDERER_ADDR"

  if [[ $DROP_METADATA_RENDERER_DEPLOY_OUTPUT == *"Contract successfully verified"* ]]; then
    echo -e "${GREEN_COLOR}- verification result: success"
  else
    echo -e "${RED_COLOR}- fail to verify contract $DROP_METADATA_RENDERER_ADDR"
    echo "$DROP_METADATA_RENDERER_DEPLOY_OUTPUT"
  fi
else
  echo "Skip deploying DropMetadataRenderer. Contract address provided ($DROP_METADATA_RENDERER_ADDR)"
fi

# ====
if [ "$FACTORY_UPGRADE_GRATE_ADDR" = "" ]
then
  echo -e "${NO_COLOR}Deploy FactoryUpgradeGate..."
  FACTORY_UPGRADE_GRATE_DEPLOY_OUTPUT=$(forge create --rpc-url $RPC_URL --private-key $PRIVATE_KEY FactoryUpgradeGate \
    --constructor-args "$WALLET_ADDRESS" `# owner` \
    --verify --verifier sourcify --verifier-url $VERIFIER_URL)
  FACTORY_UPGRADE_GRATE_ADDR=$(echo ${FACTORY_UPGRADE_GRATE_DEPLOY_OUTPUT#*"Deployed to: "} | head -c 42)
  echo -e "${GREEN_COLOR}- deployed to: $FACTORY_UPGRADE_GRATE_ADDR"

  if [[ $FACTORY_UPGRADE_GRATE_DEPLOY_OUTPUT == *"Contract successfully verified"* ]]; then
    echo -e "${GREEN_COLOR}- verification result: success"
  else
    echo -e "${RED_COLOR}- fail to verify contract $FACTORY_UPGRADE_GRATE_ADDR"
    echo "$FACTORY_UPGRADE_GRATE_DEPLOY_OUTPUT"
  fi
else
  echo "Skip deploying FactoryUpgradeGate. Contract address provided ($FACTORY_UPGRADE_GRATE_ADDR)"
fi

# ====
if [ "$ERC721_DROP_ADDR" = "" ]
then
  echo -e "${NO_COLOR}Deploy ERC721Drop..."
  ERC721_DROP_DEPLOY_OUTPUT=$(forge create --rpc-url $RPC_URL --private-key $PRIVATE_KEY ERC721Drop \
    --constructor-args \
      "0x0000000000000000000000000000000000000000" `# _zoraERC721TransferHelper` \
      $FACTORY_UPGRADE_GRATE_ADDR \
      0 `# _mintFeeAmount` \
      "$WALLET_ADDRESS" `#_mintFeeRecipient` \
      $PROTOCOL_REWARD_ADDR \
    --verify --verifier sourcify --verifier-url $VERIFIER_URL)
  ERC721_DROP_ADDR=$(echo ${ERC721_DROP_DEPLOY_OUTPUT#*"Deployed to: "} | head -c 42)
  echo -e "${GREEN_COLOR}- deployed to: $ERC721_DROP_ADDR"

  if [[ $ERC721_DROP_DEPLOY_OUTPUT == *"Contract successfully verified"* ]]; then
    echo -e "${GREEN_COLOR}- verification result: success"
  else
    echo -e "${RED_COLOR}- fail to verify contract $ERC721_DROP_ADDR"
    echo "$ERC721_DROP_DEPLOY_OUTPUT"
  fi
else
  echo "Skip deploying ERC721Drop. Contract address provided ($ERC721_DROP_ADDR)"
fi

# ====

if [ "$ZORA_CREATOR_ADDR" = "" ]
then
  echo -e "${NO_COLOR}Deploy ZoraNFTCreatorV1..."
  ZORA_CREATOR_DEPLOY_OUTPUT=$(forge create --rpc-url $RPC_URL --private-key $PRIVATE_KEY ZoraNFTCreatorV1 \
    --constructor-args \
      $ERC721_DROP_ADDR \
      $EDITION_METADATA_RENDERER_ADDR \
      $DROP_METADATA_RENDERER_ADDR \
    --verify --verifier sourcify --verifier-url $VERIFIER_URL)
  ZORA_CREATOR_ADDR=$(echo ${ZORA_CREATOR_DEPLOY_OUTPUT#*"Deployed to: "} | head -c 42)
  echo -e "${GREEN_COLOR}- deployed to: $ZORA_CREATOR_ADDR"

  if [[ $ZORA_CREATOR_DEPLOY_OUTPUT == *"Contract successfully verified"* ]]; then
    echo -e "${GREEN_COLOR}- verification result: success"
  elif [[ $ZORA_CREATOR_DEPLOY_OUTPUT == *"Contract source code already verified"* ]]; then
    echo -e "${GREEN_COLOR}- Contract "${ZORA_CREATOR_ADDR}" source code already verified"
  else
    echo -e "${RED_COLOR}- fail to verify contract $ZORA_CREATOR_ADDR"
    echo "$ZORA_CREATOR_DEPLOY_OUTPUT"
  fi
else
  echo "Skip deploying ZoraNFTCreatorV1. Contract address provided ($ZORA_CREATOR_ADDR)"
fi

# ====
if [ "$ZORA_NFT_CREATOR_PROXY_ADDR" = "" ]
then
  echo -e "${NO_COLOR}Deploy ZoraNFTCreatorProxy..."
  ZORA_NFT_CREATOR_PROXY_DEPLOY_OUTPUT=$(forge create --rpc-url $RPC_URL --private-key $PRIVATE_KEY ZoraNFTCreatorProxy \
    --constructor-args \
      $ZORA_CREATOR_ADDR \
      "0x8129fc1c" `# signature of function initialize()` \
    --verify --verifier sourcify --verifier-url $VERIFIER_URL)
  ZORA_NFT_CREATOR_PROXY_ADDR=$(echo ${ZORA_NFT_CREATOR_PROXY_DEPLOY_OUTPUT#*"Deployed to: "} | head -c 42)
  echo -e "${GREEN_COLOR}- deployed to: $ZORA_NFT_CREATOR_PROXY_ADDR"

  if [[ $ZORA_NFT_CREATOR_PROXY_DEPLOY_OUTPUT == *"Contract successfully verified"* ]]; then
    echo -e "${GREEN_COLOR}- verification result: success"
  else
    echo -e "${RED_COLOR}- fail to verify contract $ZORA_NFT_CREATOR_PROXY_ADDR"
    echo "$ZORA_NFT_CREATOR_PROXY_DEPLOY_OUTPUT"
  fi
else
  echo "Skip deploying ZoraNFTCreatorProxy. Contract address provided ($ZORA_NFT_CREATOR_PROXY_ADDR)"
fi
