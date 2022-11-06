import styled from "styled-components";
import React from "react";

const OutlineButton = styled.div`
  font-size: 20px;
  font-family: Ubuntu, sans-serif;
  border: 2px solid white;
  width: fit-content;
  padding: 10px 50px;
  text-align: center;
  cursor: pointer;
  border-radius: 8px;
  transition: 1s;
  margin: 10px;
  &:hover {
    color: #4d64fb;
    border-color: #4d64fb;
    transition: 0.3s;
    box-shadow: 0 5px 15px rgba(46, 113, 192, 0.3);
  }
`;

function test(action) {
  console.log("test clicked: ", action);
}

export const Button = ({ children, props }) => {
  return <OutlineButton onClick={
    () => {
      test(children);
    }
  } {...props}>{children}</OutlineButton>;
};
