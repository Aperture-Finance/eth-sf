import styled from "styled-components";
import uni from "../image/uni.png";
import { Button } from "./Button";

const Container = styled.div`
  width: 45vw;
  height: 90vh;
  position: absolute;
  border-top-left-radius: 2em 2em;
  border-bottom-left-radius: 2em 2em;
`;
const IMG = styled.img`
  background-image: url(${uni})
  width:100%;
  height:100%;
  object-fit: cover;
`;
const Content = styled.div`
  background: #121212;
  border-radius: 1em;
  width: 88%;
  height: 90%;
  position: absolute;
  top: 5%;
  left: 5%;
`;
export const Withdraw = () => {
  return (
    <Container>
      {/* <Content /> */}
      <Button test={"Deposit"}>Deposit</Button>
      <Button test={"withdraw"}>Withdraw</Button>
      <img src={uni} alt="aa" width="200" height="300"/>
    </Container>
  );
};
