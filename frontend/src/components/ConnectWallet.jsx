
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

  const sliceAddress = (address) => {
    return address.slice(0, 8) + '...' + address.slice(-8)
  }
  return <Container>
    <Button onClick={() => { connect(); }}>{isConnected ? sliceAddress(address) : "Connect Wallet Here"}</Button>
  </Container>
}