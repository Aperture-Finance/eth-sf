
import { Button } from './Button'
import styled from "styled-components";
import { useAccount, useConnect } from 'wagmi'
import { InjectedConnector } from 'wagmi/connectors/injected'

const Container = styled.div`
  margin-top:30px
`
export const ConnectWallet = () => {

  const { address, isConnected } = useAccount()
  const { connect } = useConnect({ connector: new InjectedConnector() })

  return <Container>
    <Button onClick={() => { connect(); }}>{isConnected ? address : "Connect Wallet Here"}</Button>
  </Container>
}