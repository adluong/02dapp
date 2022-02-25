require('@nomiclabs/hardhat-waffle');

module.exports={
  solidity: '0.8.0',
  networks: {
    ropsten:{
      url: 'https://eth-ropsten.alchemyapi.io/v2/v1Oxe_ZLWotAeHlo0EGgdpNGgNHijuRl',
      accounts: ['32e5064f8540235725c0b6d8f6aefea07649e6195eeb66500ba54a7926fac84c']
    }
  }
}