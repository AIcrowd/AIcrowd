import React from 'react';

import styles from './achievementPopup.module.scss';
import ButtonDefault from 'src/components/atoms/Button/ButtonDefault';
const {
  main,
  badgeIcon,
  descriptionText,
  titleText,
  socialText,
  socialIconWrapper,
  iconWrapper,
  shineWrapper,
} = styles;

const AchievementPopup = ({ title, description, icon, handleClick }) => {
  return (
    <div>
      <div className={main}>
        <i className="las la-times"></i>
        <div className={iconWrapper}>
          {/* Show shining animation after badge popup animation */}
          <div className={shineWrapper}>
            <span></span>
            <span></span>
          </div>
          <img src={icon} alt="badge icon" className={badgeIcon}></img>
        </div>
        <div className={titleText}>{title}</div>
        <div className={descriptionText}>{description}</div>
        <div className={socialText}>Share with your friends: </div>
        <div className={socialIconWrapper}>
          <img src="https://ui-storybook.aicrowd.com/assets/social/twitter.svg" alt="twitter logo"></img>
          <img src="https://ui-storybook.aicrowd.com/assets/social/linkedin.svg" alt="linkedin logo"></img>
          <img src="https://ui-storybook.aicrowd.com/assets/social/github.svg" alt="github logo"></img>
        </div>
        <ButtonDefault type="primary" text="Continue" handleClick={handleClick}/>
      </div>
    </div>
  );
};

export default AchievementPopup;
