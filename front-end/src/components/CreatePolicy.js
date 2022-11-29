import * as React from "react";
import * as ReactDOM from "react-dom";
import { Form, Field, FormElement } from "@progress/kendo-react-form";
import { Error } from "@progress/kendo-react-labels";
import { Input, NumericTextBox } from "@progress/kendo-react-inputs";

const CreatePolicy = () => {
  
  return (
    <React.Fragment>
      <header style={{ padding: 10, fontSize: 25, fontWeight: "bold", }}>
        New Crop Insurance Policy
      </header>
      <Form render={(formRenderProps) => (
        <FormElement style={{ maxWidth: 650, paddingLeft: 10, paddingTop: 10 }}>
            <legend className={"k-form-legend"}>
              Please fill out the Insurance Policy Details: 
            </legend>
            <div className="mb-3">
              <Field name={"ownerAddress"} component={Input} label={"Payable ETH Address"} />
            </div>
            <div className="mb-3">
              <Field name={"startDate"} component={Input} label={"Start Insurance Date"} />
            </div>
            <div className="mb-3">
              <Field name={"endDate"} component={Input} label={"End Insurance Date"} />
            </div>
            <div className="mb-3">
              <Field name={"location"} component={Input} label={"Location"} />
            </div>
            <div className="mb-3">
              <Field name={"minRain"} component={NumericTextBox} label={"Minimum Rain Amount"} />
            </div>
            <div className="mb-3">
              <Field name={"maxRain"} component={NumericTextBox} label={"Maximum Rain Amount"} />
            </div>
            <div className="mb-3">
              <Field name={"insuredAmount"} component={NumericTextBox} label={"Insured Amount"} />
            </div>
        </FormElement>
      )}
    />
    </React.Fragment>
  );
}

export default CreatePolicy;
