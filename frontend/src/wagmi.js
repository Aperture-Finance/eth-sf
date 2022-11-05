
import { createClient, configureChains, chain } from 'wagmi'
import { publicProvider } from 'wagmi/providers/public'
// import { CoinbaseWalletConnector } from 'wagmi/connectors/coinbaseWallet'
import { InjectedConnector } from 'wagmi/connectors/injected'
import { MetaMaskConnector } from 'wagmi/connectors/metaMask'
// import { WalletConnectConnector } from 'wagmi/connectors/walletConnect'

const { chains, provider, webSocketProvider } = configureChains(
    [chain.mainnet, chain.optimism, chain.optimismGoerli, chain.optimismKovan],
    [publicProvider()],
)

export const client = createClient({
    autoConnect: false,
    connectors: [
        new MetaMaskConnector({ chains }),
        // new CoinbaseWalletConnector({
        //     chains,
        //     options: {
        //         appName: 'wagmi',
        //     },
        // }),
        // new WalletConnectConnector({
        //     chains,
        //     options: {
        //         qrcode: true,
        //     },
        // }),
        new InjectedConnector({
            chains,
            options: {
                name: 'Injected',
                shimDisconnect: true,
            },
        }),
    ],
    provider,
    webSocketProvider,
})