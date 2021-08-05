import React from "react"
import PropTypes from "prop-types"

class AchievementDetails extends React.Component {
  render () {
    return (
      <div className="mainWrapper">
        <div className="titleText">{this.props.title}</div>
        <div className="descriptionText">{this.props.description}</div>
      </div>
    );
  }
}

AchievementDetails.propTypes = {
  title: PropTypes.string,
  description: PropTypes.string
};
export default AchievementDetails
