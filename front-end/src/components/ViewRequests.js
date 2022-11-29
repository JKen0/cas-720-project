import * as React from "react";
import * as ReactDOM from "react-dom";
import { Grid, GridColumn as Column } from "@progress/kendo-react-grid";
import moment from 'moment';
import { Button, ButtonGroup } from "@progress/kendo-react-buttons";
const TestRequestPolicies = require('../testData/testRequestPolicies.json');


const DetailComponent = (props) => {
    const dataItem = props.dataItem;
    return (
      <div>
        <section>
          <p>
            <strong>Insured Address:</strong> {dataItem.owner} 
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
            <strong>Insured Amount:</strong> {dataItem.insuredAmount} ETH
          </p>
        </section>
        <ButtonGroup>
          <Button className = 'k-button k-button-solid k-button-solid-success'>Accept</Button>
          <Button className = 'k-button k-button-solid k-button-solid-error'>Deny</Button>
        </ButtonGroup>
      </div>
    );
  };


const ViewRequests = () => {
    const [data, setData] = React.useState(TestRequestPolicies);

    const expandChange = (event) => {
        let newData = data.map((item) => {
          if (item.policyID === event.dataItem.policyID) {
            item.expanded = !event.dataItem.expanded;
          }

          return item;
        });
        setData(newData);
    };

    const dateCell = (props) => {
        const field = props.field || "";
        return (
            <td>
                {moment.unix(props.dataItem[field]).format("YYYY-MM-DD")}
            </td>
        ) 
    };

    return (
        <div>
          <header style={{ padding: 10, fontSize: 25, fontWeight: "bold", }}>
            View All Pending Policy Requests:
          </header>      
          <Grid data={data}
            detail={DetailComponent}
            expandField="expanded"
            onExpandChange={expandChange}
            style={{ padding: 10 }}
          >
            <Column field="policyID" title="Policy ID"/>
            <Column field="policyStatus" title="Policy Status"/>
            <Column field="startDateUnix" title="Start Insurance Date" cell={dateCell}/>
            <Column field="endDateUnix" title="End Insurance Date" cell={dateCell}/>
            <Column field="insuredAmount" title="Insured Amount" />
          </Grid>
      </div>
    );
};

export default ViewRequests;
