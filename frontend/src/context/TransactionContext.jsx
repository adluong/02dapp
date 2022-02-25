import React, {useEffect, useState} from 'react';
import {ethers} from 'ethers';

import {contractABI, contractAddress} from '../utils/constants';

export const TransactionContext = React.createContext();

//metamask instance
const { ethereum } = window;

//get the smart contract by its address, abi, and signer. Note that, the smart contracted is deployed beforehand.
const getEthereumContract = () =>{
    const provider = new ethers.providers.Web3Provider(ethereum);
    const signer = provider.getSigner();
    const transactionContract = new ethers.Contract(contractAddress, contractABI, signer);

    return transactionContract;
}

export const TransactionProvider = ({children}) => {
    //state for storing data in react.
    const [currentAccount, setCurrentAccount] = useState(""); //useState(initialstate)
    const [formData, setFormData] = useState({addressTo: '', amount: '', keyword: '', message: ''});
    const [isLoading, setIsLoading] = useState(false);
    const [transactionCount, setTransactionCount] = useState(localStorage.getItem('transactionCount'));
    const [transactions, setTransactions] = useState([]);
    //?
    const handleChange = (e, name) => {
        setFormData((prevState) => ({...prevState, [name]: e.target.value }))
    }

    const getAllTransactions = async () => {
        try {
            if(!ethereum) return alert("wallet connecting falied. Install metamask.");
            const transactionContract = getEthereumContract();
            const availableTransactions = await transactionContract.getAllTransactions();
            const structuredTransactions = availableTransactions.map((transaction) => ({
                addressTo: transaction.receiver,
                addressFrom: transaction.sender,
                timestamp: new Date(transaction.timestamp.toNumber() * 1000).toLocaleString(),
                message: transaction.message,
                keyword: transaction.keyword,
                amount: parseInt(transaction.amount._hex)/ (10 ** 18)
            }));
            console.log(structuredTransactions);
            setTransactions(structuredTransactions);          
        } catch (error) {
            console.log(error);
            throw new Error("no eth object.");
        }
    }
    const checkIfWalletIsConnected = async () => {
        try {
            //if metamask is not connected, there is not ethereum object.
            if(!ethereum) return alert("wallet connecting falied. Install metamask.");
            //wait until metamask is installed.
            const accounts = await ethereum.request({method: 'eth_accounts'});
            //after that, set the current account to the first account
            if(accounts.length) {
                setCurrentAccount(accounts[0]);
                getAllTransactions();
            } else{
                console.log("no accounts found");
            }

         console.log(accounts);

        } catch (error) {
            console.log(error);
            throw new Error("no eth object.");
        }
    }        

    const checkIfTransactionsExist = async () => {
        try {
            const transactionContract = getEthereumContract();
            const transactionCount = await transactionContract.getTransactionCount();
            window.localStorage.setItem("transactionCount", transactionCount);
        } catch (error) {
            console.log(error);
            throw new Error("no eth object.");
        }
    }

    //connect to a wallet metamask
    const connectWallet = async () => {
        try{
            if(!ethereum) return alert("wallet connecting falied. Install metamask.");
            const accounts = await ethereum.request({method: 'eth_requestAccounts'});
            setCurrentAccount(accounts[0]);
        } catch (error) {
            console.log(error);
            throw new Error("no eth object.");
        }
    }

    const sendTransaction = async () => {
        try {
            if(!ethereum) return alert("wallet connecting falied. Install metamask.");
            const {addressTo, amount, keyword, message} = formData; //destructure the input data in Wellcome.jsx, where this function is invoked.
            const transactionContract = getEthereumContract();
            const parsedAmount = ethers.utils.parseEther(amount); //convert amount to Gwei

            //send eth from an address to another. Data is received from input form.
            await ethereum.request({
                method: 'eth_sendTransaction',
                params: [{
                    from: currentAccount,
                    to: addressTo,
                    gas: '0x5208', //21000Gwei
                    value: parsedAmount._hex,
                }]
            });

            //add transaction to blockchain
            const transactionHash = await transactionContract.addToBlockchain(addressTo, parsedAmount, message, keyword);
            setIsLoading(true); //display loading status while the transaction is processed.
            console.log(`Loading - ${transactionHash.hash}`);
            await transactionHash.wait();

            setIsLoading(false);
            console.log(`Success - ${transactionHash.hash}`);
            
            const transactionCount = await transactionContract.getTransactionCount();
            setTransactionCount(transactionCount.toNumber());
            window.reload();
        } catch (error) {
            console.log(error);
            throw new Error("no eth object.");
        }
    }
    useEffect(() => {
    checkIfWalletIsConnected();
    checkIfTransactionsExist();
    }, []);

    return(
        //context for sharing data between parents and childrens. sharing components are inside the value.
        <TransactionContext.Provider value={{connectWallet, currentAccount, formData, sendTransaction, handleChange, transactions, isLoading}}>
            {children}
        </TransactionContext.Provider>
    )
}