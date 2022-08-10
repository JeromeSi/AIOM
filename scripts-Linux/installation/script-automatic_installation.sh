# GNU GENERAL PUBLIC LICENSE Version 3
# https://github.com/JeromeSi/AIOM/blob/main/scripts-Linux/installation/script-automatic_installation.sh
# by Jerome Signouret

#!/bin/bash
yes="y"
no="n"
qNewUser="Voulez-vous créer un nouvel utilisateur pour Massa ? $yes pour le créer : "
qUserName="Entrer un nom d'utilisateur : "
qPassword="Enter un mot de passe : "
qDirectoryOfMassa="Dans quel dossier j'installe le dossier massa ? "
tMassaVersion="La version de Massa est : "
tRunningNode1="Démarrage du node avec "
tRunningNode2="comme mot de passe"
qpassWordNode="Mot de passe pour le node, ne le perdez pas ! : "
qWhatIP="Que version d'IP utilisez-vous ? Répondre 4 ou 6 : "
mCreateWallet="Création d'un portefeuille.\n Il ne faut pas diffuser votre clé Secrète."
mAddStaking="Initialise le noeud pour le staking de bloc avec la clé secrète'"
qChooseWallet="Choisir un wallet : "
mFaucet="Sur le serveur Discord https://discord.com/invite/massa \n Visiter le cannal #testnet-faucet \n Utiliser l'adresse suivante pour demander 100MASS"
mWaitBootStrap="En attente de bootstrap"
mSuccessfulBootstrap="Bootstrap effectué. Le node a rejoint le réseau Massa."
mAchat="Quand c'est fait, presser la touche Entrée pour déclencher l'achat d'un roll."
mWait="Attendre 10s"
mDone="C'est fait !"
mNewWallet="Créer un nouveau wallet"
mCreateDirectory="Dossier créé $massaDirectory"
mInstallPackages="Installation des paquets nécessaires"
mSearchWalletDat="existe-t-il un fichier wallet.dat ?"
mBootstrapInProgress="Bootstrap en cours. Patienter..."
mBuyDone="Achat fait, il faut attendre 3 cycles pour que les jetons (rolls) deviennent actifs."
mEndMessage="Votre node fonctionne en tâche de fond.\n"
mFireWall="Ouverture des ports\n31244 : communication entre les noeuds\n31245 : démarrage d'un noeud\n33035 : surveillance activité du noeud"
mEndMessage="Le noeud MASSA fonctionne"

#add package
echo -e "$mInstallPackages"
sudo apt -y install locate
sudo updatedb
sudo apt -y install wget curl ufw

#problem with libssl1.1 and ubuntu 22.04
if hostnamectl | grep "22.04"
	then
	wget -q http://fr.archive.ubuntu.com/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1f-1ubuntu2.16_amd64.deb
	sudo dpkg -i ./libssl1.1_1.1.1f-1ubuntu2.16_amd64.deb
	rm ./libssl1.1_1.1.1f-1ubuntu2.16_amd64.deb
fi

# create a new user ?
echo
read -p "$qNewUser" rep
if [ $rep == $yes ]
	then
	echo
	read -p "$qUserName" userName
	read -s -p "$qPassword" passWord
	echo
	pass=$(perl -e 'print crypt($ARGV[0], "passWord")' $passWord)
	useradd -m -p "$pass" "$userName"
fi

# directory for Massa
echo
read -e -p "$qDirectoryOfMassa" -i "/home/$(whoami)/MASSA" massaDirectory
echo "$massaDirectory"
if [ ! -d "$massaDirectory" ]
	then
	mkdir "$massaDirectory"
	echo "$mCreateDirectory"
fi
cd "$massaDirectory"

# Current massa version
version=$(curl -s https://github.com/massalabs/massa | grep "class.*tag/TEST" | awk -F '/' '{print $6}' | sed 's/">//')
echo "$tMassaVersion $version"
wget -q https://github.com/massalabs/massa/releases/download/$version/massa_"$version"_release_linux.tar.gz
tar xzf massa_"$version"_release_linux.tar.gz
mv ./massa ./massa-"$version"
ln -s ./massa-"$version" ./massa

# Create config.toml
cd "$massaDirectory"/massa/massa-node/config
wget -q http://massa.alphatux.fr/bootstrapper.toml
ipv4=$(curl -s ifconfig.me)
ipv6=$(curl -s ifconfig.co)
echo
echo -e "ipv4 : $ipv4\nipv6 : $ipv6 "
read -p "$qWhatIP" rep
echo "[network]" > ./config.toml
if [ $rep == "4" ]
	then
	echo -e "	routable_ip = \"$ipv4\"\n" >> ./config.toml
	else
	echo -e "	routable_ip = \"$ipv6\"\n" >> ./config.toml
fi
cat bootstrapper.toml >> ./config.toml
echo -e "retry_delay = 15000\n" >> ./config.toml

#password of massa-node and massa-client
echo
read -p "$qpassWordNode" passWordNode
echo "$tRunningNode1 - $passWordNode - $tRunningNode2"

#configure and/or create wallet
function createWallet()
{
	echo -e "$mCreateWallet"
	cd "$massaDirectory"/massa/massa-client
	./massa-client -p $passWordNode wallet_generate_secret_key
	echo "$mAddStaking"
	secretKey=$(./massa-client -p $passWordNode wallet_info | grep "Secret key" | sed 's/Secret key\: //g')
	echo "node_add_staking_secret_keys $secretKey"
	./massa-client -p $passWordNode node_add_staking_secret_keys $secretKey
}

function runNode()
{
	cd "$massaDirectory"/massa/massa-node
	logfile=$1
	nohup ./massa-node -p $passWordNode &>> $logfile &
	echo "$mBootstrapInProgress"
	sleep 2s
	while [ "$(grep "Successful bootstrap" $logfile)" == "" ]
		do
		sleep 10s
		echo "$mWaitBootStrap"
		done
	echo "$mSuccessfulBootstrap"
}

echo
echo -e "$mSearchWalletDat"
nWalletDat=$(locate wallet.dat | wc -l)
if [[ $nWalletDat -gt 0 ]]
	then
		thelistofwallet=$(echo -e "$(locate wallet.dat)\n$mNewWallet")
		echo "$thelistofwallet"  | cat -n
		read -p "$qChooseWallet" rep
		if [[ $(($nWalletDat+1)) == $rep ]]
			then
			runNode "$massaDirectory/massa/massa-node/Node-$(date +%F_%T).log"
			createWallet
			else
			walletFile=$(echo "$thelistofwallet" | sed -n "$rep p")
			cp $walletFile "$massaDirectory"/massa/massa-client/
			thelistofnodePrivKey=$(echo -e "$(locate node_privkey.key)")
			echo "$thelistofnodePrivKey"  | cat -n
			echo "On utilise le $rep"
			nodePrivKeyFile=$(echo "$thelistofnodePrivKey" | sed -n "$rep p")
			echo "$nodePrivKeyFile"
			cp "$nodePrivKeyFile" "$massaDirectory"/massa/massa-node/config/
			runNode "$massaDirectory/massa/massa-node/Node-$(date +%F_%T).log"
			cd "$massaDirectory"/massa/massa-client
			secretKey=$(./massa-client -p $passWordNode wallet_info | grep "Secret key" | sed 's/Secret key\: //g')
			echo "node_add_staking_secret_keys $secretKey"
			./massa-client -p $passWordNode node_add_staking_secret_keys $secretKey
		fi
	else
		runNode "$massaDirectory/massa/massa-node/Node-$(date +%F_%T).log"
		createWallet
fi

#claim de faucet and buy a roll
echo
echo -e "$mFaucet"
cd "$massaDirectory"/massa/massa-client/
address=$(./massa-client -p $passWordNode wallet_info | grep Address | sed 's/Address: //g')
echo "$address"
read -p "$mAchat" rep
until [[ $finalBalance -gt 0 ]]
do
	finalBalance=$(./massa-client -p $passWordNode wallet_info | grep  "Final balance" | sed 's/.*Final balance: //g')
	sleep 10s
	echo "$mWait"
done
./massa-client -p $passWordNode buy_rolls $address 1 0
echo "$mBuyDone"

#open ports 31244 31245 et 33035
echo
echo -e "$mFireWall"
sudo ufw enable
sudo ufw allow 31244
sudo ufw allow 31245
sudo ufw allow 33035
sudo ufw status

echo -e "$mEndMessage"
