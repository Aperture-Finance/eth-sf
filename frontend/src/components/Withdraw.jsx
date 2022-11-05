import styled from "styled-components";
import bg from "../image/bg.jpg";

const Container = styled.div`
  width: 45vw;
  height: 90vh;
  position: absolute;
  right: 0;
  top: 5vh;
  border-top-left-radius: 2em 2em;
  border-bottom-left-radius: 2em 2em;
  overflow: hidden;
`;
const IMG = styled.img`
  background-image: url(${bg})
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
      <Content />
      <IMG src={bg} alt="" />
    </Container>
  );
};
