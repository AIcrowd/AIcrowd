import React from 'react';

import AchievementDetail from 'src/components/molecules/AchievementDetail';
import AchievementProgress from 'src/components/molecules/AchievementProgress';
import styles from './achievementListItem.module.scss';
const { main, shareText } = styles;

const AchievementListItem = ({ icon, progress, target, title, description }) => {
  return (
    <div>
      <div className={main}>
        <img src={icon}></img>
        <AchievementProgress progress={progress} target={target} />
        <div style={{ paddingTop: '27px' }}>
          <AchievementDetail title={title} description={description} />
        </div>
        <span className={shareText}>Share</span>
      </div>
    </div>
  );
};
export default AchievementListItem;
