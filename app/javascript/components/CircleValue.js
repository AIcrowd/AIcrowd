import React from 'react';

const CircleValue = ({ value }) => {
  return (
    <div className='circle-value'>
      <span className='circle-value-content'>+ {value}</span>
    </div>
  );
};
export default CircleValue;
