#!/bin/bash
yes="y"
no="n"
qNewUser="Voulez-vous créer un nouvel utilisateur pour Massa ? $yes pour le créer : "
qUserName="Entrer un nom d'utilisateur : "
qPassword="Enter un mot de passe : "
qDirectoryOfMassa="Dans quel dossier j'installe le dosier massa ? "
tMassaVersion="La version de Massa est :"
tRunningNode1="Démarrage du node avec "
tRunningNode2="comme mot de passe"
qpassWordNode="Mot de passe pour le node, ne le perdez pas ! :"
qWhatIP="Que version d'IP utilisez-vous ? Répondre 4 ou 6 : "
mCreateWallet="Création d'un portefeuille.\n Il ne faut pas diffuser votre clé Secrète."
mAddStaking="Initialise le noeud pour le staking de bloc avec la clé secrète'"
qChooseWallet="Choisir un wallet : "
mFaucet="Sur le serveur Discord https://discord.com/invite/massa \n Visiter le cannal #testnet-faucet \n Utiliser l'adresse suivant pour demander 100MASS"
mWaitBootStrap="En attente de bootstrap"
mSuccessfulBootstrap="Bootstrap effectué. Le node a rejoint le réseau Massa."
mAchat="Quand c'est fait, presser la touche Entrée pour déclencher l'achat d'un roll.'"
mWait="Attendre 10s"
mDone="C'est fait !"
mNewWallet="Créer un nouveau wallet"

# create a new user ?
echo "$qNewUser"
read -p "$qNewUser" rep
if [ $rep == $yes ]
	then
	echo
	read -p "$qUserName" userName
	read -s -p "$qPassword" passWord
	echo
	#pass=$(perl -e 'print crypt($ARGV[0], "passWord")' $passWord)
	#useradd -m -p "$pass" "$userName"
fi

# directory for Massa
echo
read -e -p "$qDirectoryOfMassa" -i "/home/$(whoami)/MASSA" massaDirectory
echo "$massaDirectory"
if [ ! -d "$massaDirectory" ]
	mkdir "$massaDirectory"
cd "$massaDirectory"

# Current massa version
version=$(curl -s https://github.com/massalabs/massa | grep "tag/TEST" | awk -F '/' '{print $6}' | sed 's/">//')
echo "$tMassaVersion $version"
#~ wget https://github.com/massalabs/massa/releases/download/$version/massa_"$version"_release_linux.tar.gz
#~ tar xzf massa_"$version"_release_linux.tar.gz
#~ mv ./massa ./massa-"$version"
#~ ln -s ./massa-"$version" ./massa

# Create config.toml
cd "$massaDirectory"/massa-node/config
ipv4=$(curl ifconfig.me)
ipv6=$(curl ifconfig.co)
echo
read -p "$qWhatIP" rep
echo "[network]" > ./config.toml
if [ $rep == "4"]
	then
	echo "	routable_ip = \"$ipv4\""
	else
	echo "	routable_ip = \"$ipv6\""

# Running the node
echo
read -p "$qpassWordNode" passWordNode
echo "$tRunningNode1 $passWordNode $tRunningNode1"
cd "$massaDirectory"/massa-node
logfile="$massaDirectory/massa-node/Node-$(date +%F_%T).log"
nohup ./massa-node -p $passWordNode &>> ~/$logfile &

while [ "$(grep "Successful bootstrap" $logfile)" = "" ]
	do
	sleep 10s
	echo "$mWaitBootStrap"
	done
echo "$mSuccessfulBootstrap"

#configure and/or create wallet
function createWallet()
{
	echo -e "$mCreateWallet"
	cd "$massaDirectory"/massa-client
	./massa-client -p $passWordNode wallet_generate_secret_key
	echo "$mAddStaking"
	./massa-client -p $passWordNode "node_add_staking_secret_keys $(./massa-client -p $passWordNode wallet_info | grep "Secret key" | sed 's/Secret key\: //g')"
}

nWalletDat=$(locate wallet.dat | wc -l)
if [[ $n -eq 0 ]]
	then
		createWallet
	else
		thelistofwallet=$(echo -e "$(locate wallet.dat)\n$mNewWallet" | cat -n)
		nWallet=$(echo "$thelistofwallet" | wc -l)
		echo "$thelistofwallet"
		echo "$qChooseWallet" rep
		if [[ $nWallet == $rep ]]
			then
			createWallet
			else
			walletFile=$(echo "$thelistofwallet" | sed -n "$rep p")
			nodePrivKeyFile=$(echo $(echo "$thelistofwallet" | sed -n "$rep p" | sed 's/client\/wallet.dat//g')"node/config/node_privkey.key")
			cp $walletFile ./
			cp $nodePrivKeyFile ../massa-node/config/
fi

#claim de faucet and buy a roll
echo
echo "$mFaucet"
address=$(./massa-client -p $passWordNode wallet_info | grep Address | sed 's/Address: //g')
echo "$address"
read -p "$mAchat" rep
do
	finalBalance=$(./massa-client -p $passWordNode wallet_info | grep  "Final balance" | sed 's/.*Final balance: //g')
	sleep 10s
	echo "$mWait"
until [[ $finalBalance -gt 0 ]
./massa-client -p $passWordNode "buy_rolls $address 1 0"
echo "$mDone"
