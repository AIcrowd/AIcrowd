import React from 'react';
import AvatarWithTier from './AvatarWithTier'

const AvatarGroup = ({ users, loading }) => (
  <div className='avatar-group'>
    {users.map((user, index) => {
      const { tier, image } = user;
      return (
        <div className='avatar-group-item' key={index}>
          <AvatarWithTier tier={tier} image={image} loading={loading} />
        </div>
      );
    })}
  </div>
);

export default AvatarGroup;
