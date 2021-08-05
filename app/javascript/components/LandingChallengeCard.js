import React from "react"
import PropTypes from "prop-types"

import AvatarGroup from "./AvatarGroup"
import CircleValue from "./CircleValue"


const LandingChallengeCard = ({ image, name, prize, users, color }) => {
  return (
    <div className="main" style={{ background: color }}>
      <img src={image}></img>
      <div className="textWrapper">
        <div className="titleText" style={{ color: `${color === '#FFFFFF' ? '#1f1f1f' : '#ffffff'}` }}>
          {name}
        </div>
        <div className="prizeText" style={{ color: `${color === '#FFFFFF' ? '#1f1f1f' : '#ffffff'}` }}>
          {prize}
        </div>
      </div>
      <div className="participantsWrapper">
        <AvatarGroup users={users} />
        <div className="circleValue">
          <CircleValue value={25} />
        </div>
      </div>
    </div>
  )
}


export default LandingChallengeCard
