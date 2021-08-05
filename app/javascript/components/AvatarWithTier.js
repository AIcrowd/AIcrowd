import React from 'react';
import Skeleton from 'react-loading-skeleton';


const AvatarWithTier = ({ tier, image, size, loading }) => {
  return (
    <div>
      {loading ? (
        <div>
          <Skeleton circle={true} width={34} height={34} />
        </div>
      ) : (
        <div className={`${`user-rating-${tier}`} ${size ? `user-rating-${size}` : ''}`}>
          <img className="avatar" src={image} alt="User avatar"></img>
        </div>
      )}
    </div>
  );
};
export default AvatarWithTier;
