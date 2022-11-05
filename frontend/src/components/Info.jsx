import styled from "styled-components";

const Title = styled.div`
  font-size: 60px;
  font-family: Ubuntu, sans-serif;
  font-weight: 700;
`;
const SubTitle = styled.div`
  margin-top: 10px;
  font-size: 30px;
  font-family: Ubuntu, sans-serif;
`;

const Text = styled.div`
  font-size: 14px;
  width: 90%;
  margin-top: 25px;
  line-height: 1.6;
`;
// const Red = styled.span`
//   color: #F35979;
// `
const Yellow = styled.span`
  color: #fbcc1a;
`;
const Blue = styled.span`
  color: #4d64fb;
`;
const Green = styled.span`
  color: #e79d97;
`;
export const Info = () => {
  return (
    <div>
      <Title>
        <Yellow>Crab</Yellow> Market Leveraged <Green>Farming</Green>
      </Title>
      <SubTitle>
        AKA <Blue>Pseudo Delta Neutral</Blue> Strategies
      </SubTitle>
      <Text>
        Our CMLF strategy is sometimes referred to as a psuedo delta neutral
        strategy. It refers to variant of delta neutral strategies that involves
        using leverage to be a liquidity provider (LP). The leverage ratio is
        around 3X which allows users to earn 3X the amount of swap fees less any
        cost associated with borrowing the assets and neccesary rebalancing.{" "}
      </Text>
    </div>
  );
};
