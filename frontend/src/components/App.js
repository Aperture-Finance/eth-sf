import styled from "styled-components";
import { Withdraw } from "./Withdraw";
import { Info } from "./Info";
import { ConnectWallet } from "./ConnectWallet";
import uni from "../image/uni.png";

const Body = styled.div`
  positoin: relative;
  display: grid;
  grid-template-columns: 50% 50%;
  width: 100vw;
  height: 100vh;
  overflow: hidden;
`;

const LeftContainer = styled.div`
  padding: 10%;
  margin: auto;
`;
function App() {
  return (
    <Body>
      <LeftContainer>
        <Info />
        <ConnectWallet />
      </LeftContainer>
      <LeftContainer>
        <Withdraw />
      </LeftContainer>
    </Body>
  );
}

export default App;
