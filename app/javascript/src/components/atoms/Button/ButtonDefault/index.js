import React from 'react';
import Link from 'next/link';

import styles from './buttonDefault.module.scss';

const ButtonDefault = ({ type, text, disabled, hidden, iconClass, to, handleClick, size, iconColor }) => {
  const largeButton = size === 'large' ? styles.large : '';
  const wideButton = size === 'wide' ? styles.wide : '';

  // Do not show button if hidden is true
  if (hidden) {
    return <div></div>;
  }
  return (
    <div>
      {/* Show button with icon */}
      {iconClass && iconClass.length > 0 ? (
        <div>
          <Link href={to || '/'} passHref={true}>
            <button
              type="button"
              className={`${styles[`btn-${type}`]} ${largeButton} ${wideButton}`}
              disabled={disabled}
              onClick={window.hideBadgesModal}>
              {text}
              &nbsp;
              <i className={`las la-${iconClass}`} style={{ color: iconColor }} />
            </button>
          </Link>
        </div>
      ) : (
        <Link href={to || '/'} passHref={true}>
          <button
            type="button"
            className={`${styles[`btn-${type}`]} ${largeButton} ${wideButton}`}
            disabled={disabled}
            onClick={window.hideBadgesModal}>
            {text}
          </button>
        </Link>
      )}
    </div>
  );
};
export default ButtonDefault;
