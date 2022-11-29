import * as React from "react";
import * as ReactDOM from "react-dom";
import { Grid, GridColumn as Column } from "@progress/kendo-react-grid";
import moment from 'moment';
const TestPolicies = require('../testPolicies.json');


const DetailComponent = (props) => {
    const dataItem = props.dataItem;
    return (
      <section>
        <p>
          <strong>Policy ID:</strong> {dataItem.policyID}
        </p>
        <p>
          <strong>Policy Status:</strong> {dataItem.policyStatus}
        </p>
        <p>
          <strong>Policy Start Date:</strong> {moment.unix(dataItem.startDateUnix).format("YYYY-MM-DD")} 
        </p>
        <p>
          <strong>Policy End Date:</strong> {moment.unix(dataItem.endDateUnix).format("YYYY-MM-DD")} 
        </p>
        <p>
          <strong>Latitude:</strong> {dataItem.lat} °
        </p>
        <p>
          <strong>Longitude:</strong> {dataItem.lng} °
        </p>
        <p>
          <strong>Minimum Required Rain:</strong> {dataItem.minRain / 100} mm
        </p>
        <p>
          <strong>Maximum Required Rain:</strong> {dataItem.maxRain / 100} mm
        </p>
        <p>
          <strong>Current Policy Rain Amount:</strong> {dataItem.currentRain / 100} mm
        </p>
        <p>
          <strong>Insured Amount:</strong> {dataItem.insuredAmount} ETH
        </p>
      </section>
    );
  };


const ViewPolicies = () => {
    const [data, setData] = React.useState(TestPolicies);

    const expandChange = (event) => {
        let newData = data.map((item) => {
          if (item.policyID === event.dataItem.policyID) {
            item.expanded = !event.dataItem.expanded;
          }

          return item;
        });
        setData(newData);
    };

    return (
        <div>
        <Grid data={data}
          detail={DetailComponent}
          expandField="expanded"
          onExpandChange={expandChange}
        >
          <Column field="policyID" title="Policy ID" />
          <Column field="policyStatus" title="Policy Status" />
          <Column field="startDateUnix" title="Start Insurance Date" />
          <Column field="endDateUnix" title="End Insurance Date" />
          <Column field="insuredAmount" title="Insured Amount" />
        </Grid>
      </div>
    );
};

export default ViewPolicies;
