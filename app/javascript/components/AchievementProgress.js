import React from "react"
import PropTypes from "prop-types"

const AchievementProgress = ({ target, progress }) => {
  debugger;

  const [totalProgress, setTotalProgress] = React.useState(0);
  const [isEmpty, setIsEmpty] = React.useState({
    bronze: true,
    silver: true,
    gold: true
  });

  const { bronze_count, silver_count, gold_count } = target;
  const totalTargetCount = bronze_count + silver_count + gold_count;
  const fillRef = React.useRef(null);

  // fill the bar based on progress completed
  React.useEffect(() => {
    // calculate progress of achievements
    const bronzeProgress = (progress / bronze_count) * 100;
    const silverProgress = (progress / silver_count) * 100;
    const goldProgress = (progress / gold_count) * 100;

    // check if progress 100% or not;
    const bronzeProgressPercent =
      bronzeProgress > 100 ? 100 : bronzeProgress;
    const silverProgressPercent =
      silverProgress > 100 ? 100 : silverProgress;
    const goldProgressPercent = goldProgress > 100 ? 100 : goldProgress;

    // Divide progress into 3 parts
    // calculate individual bar progress;
    const bronzeBarFill = (33 * bronzeProgressPercent) / 100;
    const silverBarFill = (33 * silverProgressPercent) / 100;
    const goldBarFill = (33 * goldProgressPercent) / 100;

    // check if individual bar progress is 100% or not;
    const bronzeBarFillPercent = bronzeBarFill > 100 ? 33 : bronzeBarFill;
    const silverBarFillPercent = silverBarFill > 100 ? 33 : silverBarFill;
    const goldBarFillPercent = goldBarFill > 100 ? 33 : goldBarFill;

    // Fill color in bar based on progress in each achievement
    if (progress > gold_count) {
      // if progress is greater then  gold_count fill progress to 100
      setTotalProgress(100);
      setIsEmpty({
        isEmpty,
        bronze: false,
        silver: false,
        gold: false
      });
      // if progress is less then or equal to bronze
    } else if (progress <= bronze_count) {
      setTotalProgress(bronzeBarFillPercent);
      if (progress === bronze_count) {
        setIsEmpty({isEmpty, bronze: false });
      }
      fillRef.current.style.background =
        "linear-gradient(141.18deg, #de4b46, #cb2a24)";
      // if progress is less then or equal to silver
    } else if (progress > bronze_count && progress <= silver_count) {
      setTotalProgress(bronzeBarFillPercent + silverBarFillPercent);
      setIsEmpty({isEmpty, bronze: false });
      if (progress === silver_count) {
        setIsEmpty({
          isEmpty,
          bronze: false,
          silver: false
        });
      }
      fillRef.current.style.background =
        "linear-gradient(141.18deg, #de4b46, #cb2a24,  #cd672d, #a35224)";
      // if progress is less then or equal to gold
    } else if (progress > silver_count && progress <= gold_count) {
      setTotalProgress(
        bronzeBarFillPercent + silverBarFillPercent + goldBarFillPercent
      );
      setIsEmpty({ isEmpty, bronze: false, silver: false });
      if (progress === gold_count) {
        setIsEmpty({
          isEmpty,
          bronze: false,
          silver: false,
          gold: false
        });
      }
      fillRef.current.style.background =
        "linear-gradient(141.18deg, #de4b46, #cb2a24,  #cd672d, #a35224,  #a2a3a3, #8a8a8a)";
    }

    fillRef.current.style.width = `${totalProgress}%`;
  }, [target, progress, totalProgress, setTotalProgress]);

  return (
      <div>
        <div className="targetText">
          {progress}/{totalTargetCount}
        </div>
        <div className="emptyLine">
          <div className="fill" ref={fillRef}>
            <div className="dot first">
              {/* <div className={redempty}></div>} */}
            </div>
            <div className="dot bronze">
              {isEmpty.bronze && <div className="bronzeempty"></div>}
            </div>
            <div className="dot silver">
              {isEmpty.silver && <div className="silverempty"></div>}
            </div>
            <div className="dot gold">
              {isEmpty.gold && <div className="goldempty"></div>}
            </div>
          </div>
        </div>
      </div>
  );
}


export default AchievementProgress


