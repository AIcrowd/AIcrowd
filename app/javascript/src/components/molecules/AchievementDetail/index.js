import React from 'react';

import styles from './achievementDetail.module.scss';
const { mainWrapper, titleText, descriptionText } = styles;

const AchievementDetail = ({ title, description }) => {
  return (
    <div>
      <div className={mainWrapper}>
        <div className={titleText}>{title}</div>
        <div className={descriptionText}>{description}</div>
      </div>
    </div>
  );
};

export default AchievementDetail;
