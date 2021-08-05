/* eslint no-console:0 */

require('datatables');
require('chartkick');
require("chart.js");

import '../react_components/index.js';
import '../stimulus_js/index.js';
// Support component names relative to this directory:
var componentRequireContext = require.context("../../../node_modules/aicrowd-components-library/src/components", true);
var ReactRailsUJS = require("react_ujs");
ReactRailsUJS.useContext(componentRequireContext);
