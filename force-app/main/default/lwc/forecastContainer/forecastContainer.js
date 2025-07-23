import fetchPaymentsOfOpportunity from '@salesforce/apex/ForecastController.fetchPaymentsOfOpportunity';
import queryMonthlyPayments from '@salesforce/apex/ForecastController.queryMonthlyPayments';
import chartjs from '@salesforce/resourceUrl/ChartJS';
import { NavigationMixin } from "lightning/navigation";
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { api, LightningElement, track, wire } from 'lwc';

import forecast_container_title from '@salesforce/label/c.rooms_forecast_container_title';
import table_detail_title from '@salesforce/label/c.rooms_table_detail_title';

import mpTableContractType from '@salesforce/label/c.rooms_MPTableContractType';
import mpTableDeskNumber from '@salesforce/label/c.rooms_MPTableDeskNumber';
import mpTableEndDate from '@salesforce/label/c.rooms_MPTableEndDate';
import mpTableFinalPrice from '@salesforce/label/c.rooms_MPTableFinalPrice';
import mpTableLocation from '@salesforce/label/c.rooms_MPTableLocation';
import mpTableName from '@salesforce/label/c.rooms_MPTableName';
import mpTableProductName from '@salesforce/label/c.rooms_MPTableProductName';
import mpTableStartDate from '@salesforce/label/c.rooms_MPTableStartDate';
import desk_btnGrp from '@salesforce/label/c.rooms_desk_btnGrp';
import forecastTitle from '@salesforce/label/c.rooms_forecastTitle';
import MPTableSegmentation from '@salesforce/label/c.rooms_forecast_MPTableSegmentation';
import date from '@salesforce/label/c.rooms_forecast_date';
import location from '@salesforce/label/c.rooms_forecast_location';
import revenue from '@salesforce/label/c.rooms_forecast_revenue';
import segmentation from '@salesforce/label/c.rooms_forecast_segmentation';
import renewalCanvasTitle from '@salesforce/label/c.rooms_renewal_canvas';
import statusIncomesTitle from '@salesforce/label/c.rooms_status_incomes';




window.log =  (value) => JSON.parse(JSON.stringify(value));

export default class ForecastContainer extends NavigationMixin(LightningElement) {
    @track chartInit = false;
    @track chart;
    @track displaySelected = 'segmentation';
    @api recordId;
    @track data;
    @track filteredData;
    @track allData;
    @track selectedFilters = {};
    @track dataToDisplay;
    @track tableBody;
    @track selectedXAxis = 'month-year';
    @track selectedYAxis = 'totalFinalPrice';
    @track columnsTable = [];
    @track isLocation = false;

    customLabels = {
        forecast_container_title,
        table_detail_title,
        mpTableContractType,
        mpTableDeskNumber,
        mpTableEndDate,
        mpTableFinalPrice,
        MPTableSegmentation,
        mpTableLocation,
        mpTableName,
        mpTableProductName,
        mpTableStartDate,
        forecastTitle,
        renewalCanvasTitle,
        statusIncomesTitle,
        revenue,
        date,
        location,
        segmentation,
        desk_btnGrp,

    };
    dataDetail;
    @track isEmptyTable = true;

    // Fetches data from Apex and initializes chart with data if available
    @wire(fetchPaymentsOfOpportunity)
    fetchData({ data, error }) {
        if (error) {
            this.showToast('Error occurred in FetchData', error.message, 'error');
        } else if (data) {
            console.log('DATA =' , JSON.stringify(data));

            this.data = data;
            this.allData = data;

            if (this.chart) {
                this.updateChart();
            }
        }
    }

    // Initializes chart after the component renders and the Chart.js library is loaded
    connectedCallback(){
        const {
            mpTableContractType,
            mpTableDeskNumber,
            mpTableEndDate,
            mpTableFinalPrice,
            MPTableSegmentation,
            mpTableLocation,
            mpTableName,
            mpTableStartDate
        } = this.customLabels;

        this.columnsTable = [
            mpTableName,
            mpTableStartDate,
            mpTableEndDate,
            mpTableDeskNumber,
            mpTableContractType,
            mpTableLocation,
            mpTableFinalPrice,
            MPTableSegmentation
        ];

    }

    renderedCallback() {
        if (this.chartInit) {
            return;
        }
        this.chartInit = true;
        loadScript(this, chartjs)
            .then(() => {
                const ctx = this.template.querySelector('canvas.barchart').getContext('2d');
                this.chart = new window.Chart(ctx, this.config);
                if (this.data) {
                    this.updateChart();
                }
            })
            .catch(error => {
                this.showToast('Error occurred in RenderedCallback', error.message, 'error');
            });
    }

    get xAxisOptions() {
        return [
            { label: 'Month-Year', value: 'month-year' },
            { label: 'Location', value: 'location' },
        ];
    }



    ordinateFormatChange(event){

        this.selectedYAxis = event.detail;
        this.updateChart();
    }
    forecastDisplayChange(event){

        this.displaySelected = event.detail;
        this.isLocation = this.displaySelected == 'location';
        this.isEmptyTable = true;
        this.updateChart();
    }

    handleSubmitFilters(event){

        const filters = event.detail;
        console.log('$$filters :',JSON.stringify(filters));

        const {productSelectedFilter, areaSelectedFilter, locationSelectedFilter, productSubTypeSelectedFilter, productTypeSelectedFilter, productFamilySelectedFilter } = filters;


        if(Object.keys(filters).length === 0){
            this.data = this.allData;
        }

        this.data = this.allData.filter(item => {

            let dateCondition = this.isValidDate(filters, item);

            if(dateCondition && (!productSelectedFilter && !locationSelectedFilter && !areaSelectedFilter && !productSubTypeSelectedFilter && !productTypeSelectedFilter && !productFamilySelectedFilter)){
                return true;
            }

            let productCondition = productSelectedFilter == 'All' || !productSelectedFilter;
            let areaCondition = areaSelectedFilter == 'All' || areaSelectedFilter == item.area || !areaSelectedFilter;
            let locationCondition = locationSelectedFilter && locationSelectedFilter.includes('All') || (locationSelectedFilter && locationSelectedFilter.includes(item.locationName))   || !locationSelectedFilter || locationSelectedFilter.length === 0;
            let productFamiliesCondition = productFamilySelectedFilter == 'All' || productFamilySelectedFilter == item.productFamily || !productFamilySelectedFilter ;
            let productTypesCondition = productTypeSelectedFilter == 'All' || productTypeSelectedFilter == item.productType || !productTypeSelectedFilter;
            let productSubTypesCondition = productSubTypeSelectedFilter == 'All' || productSubTypeSelectedFilter == item.productSubType || !productSubTypeSelectedFilter;

            return locationCondition && dateCondition && productCondition && areaCondition  && productSubTypesCondition && productTypesCondition && productFamiliesCondition ;
        });


        this.updateChart();

    }

    isValidDate(filters, item){
        const { startMonthFilter, startYearFilter, endMonthFilter, endYearFilter } = filters;

        if (!startMonthFilter && !startYearFilter && !endMonthFilter && !endYearFilter) {
            return true;
        }

        const itemDate = new Date(item.year, item.month - 1);
        let startDate = null;
        let endDate = null;

        if (!startYearFilter || startYearFilter === 'All') {
            startDate = startMonthFilter ? new Date(item.year, parseInt(startMonthFilter) - 1) : itemDate;
        } else {
            startDate = new Date(parseInt(startYearFilter), startMonthFilter ? parseInt(startMonthFilter) - 1 : 0);
        }

        if (!endYearFilter || endYearFilter === 'All') {
            endDate = endMonthFilter ? new Date(item.year, parseInt(endMonthFilter) - 1) : itemDate;
        } else {
            endDate = new Date(parseInt(endYearFilter), endMonthFilter ? parseInt(endMonthFilter) - 1 : 11);
        }

        return itemDate >= startDate && itemDate <= endDate;

    }


    handleXAxisChange(event) {
        this.selectedXAxis = event.target.value;
        this.updateChart();
    }

    handleYAxisChange(event) {
        this.selectedYAxis = event.target.value;
        this.updateChart();
    }

    handleLocationFilterChange(event) {
        this.selectedFilters.location = event.target.value;
        this.updateChart();
    }

    get availableLocations() {
        return [...new Set(this.data.map(item => item.locationName))];
    }

    config = {
        type: 'bar',
        data: {
            labels: [],
            datasets: []
        },
        options: {
            interaction: {
                mode: 'nearest'
            },
            onClick: this.handleChartClick.bind(this),
            plugins: {
                tooltip: {
                    enabled: false, // desactivate the default tooltip
                    external: this.customTooltip.bind(this),
                    callbacks: {
                        labelColor: function(context) {
                            return {
                                borderColor: 'rgb(0, 0, 255)',
                                backgroundColor: 'rgb(255, 0, 0)',
                                borderWidth: 2,
                                borderDash: [2, 2],
                                borderRadius: 2,
                            };
                        },
                        labelTextColor: function(context) {
                            return '#fff';
                        },
                        label: (tooltipItem) => {
                            const datasetIndex = tooltipItem.datasetIndex;
                            const index = tooltipItem.dataIndex;
                            const value = tooltipItem.dataset.data[index];
                            const location = tooltipItem.dataset.label;
                            const date = this.chart.data.labels[index];
                            const labelDisplayed = this.displaySelected === 'segmentation'
                            ? this.customLabels.segmentation
                            : this.customLabels.location;

                            return `${labelDisplayed}: ${location} <br>${this.customLabels.date}: ${date} <br>${
                                this.selectedYAxis === 'deskNumber' ? this.customLabels.desk_btnGrp : this.customLabels.revenue
                            }: ${value} ${this.selectedYAxis === 'deskNumber' ? '' : 'sh out of ' }`;

                        }

                    }
                },
                title: {
                    display: true,
                    text: ''
                },
            },
            responsive: true,
            maintainAspectRatio: false,
            scales: {
                x: {
                    stacked: true
                },
                y: {
                    stacked: true
                }
            }
        }
    };
    customTooltip(context) {
        let tooltipEl = this.template.querySelector('.chartjs-tooltip');

        if (!tooltipEl) {
            tooltipEl = document.createElement('div');
            tooltipEl.className = 'chartjs-tooltip';
            tooltipEl.style.opacity = 1;
            tooltipEl.style.position = 'absolute';
            tooltipEl.style.background = '#4d4d76';
            tooltipEl.style.color = 'white';
            tooltipEl.style.borderRadius = '3px';
            tooltipEl.style.pointerEvents = 'none';
            tooltipEl.style.transform = 'translate(-50%, 0)';
            tooltipEl.style.padding = '10px';
            tooltipEl.style.fontSize = '12px';
            this.template.querySelector('.chart-container').appendChild(tooltipEl);
        }

        const tooltipModel = context.tooltip;
        if (tooltipModel.opacity === 0) {
            tooltipEl.style.opacity = 0;
            return;
        }

        if (tooltipModel.body) {
            const titleLines = tooltipModel.title || [];
            const bodyLines = tooltipModel.body.map(bodyItem => bodyItem.lines);

            let innerHtml = '<div>';

            titleLines.forEach(function (title) {
                innerHtml += `<strong>${title}</strong><hr style="margin: 0"><br>`;
            });

            bodyLines.forEach(function (body, i) {
                const colors = tooltipModel.labelColors[i];
                const style = `background:#4d4d76; border-color:${colors.borderColor}; border-width: 2px`;
                const span = `<span style="${style}"></span>`;
                innerHtml += `${span} ${body}<br>`;
            });

            innerHtml += '</div>';

            tooltipEl.innerHTML = innerHtml;
        }

        const positionY = this.chart.canvas.offsetTop;
        const positionX = this.chart.canvas.offsetLeft;

        tooltipEl.style.opacity = 1;
        tooltipEl.style.left = positionX + tooltipModel.caretX + 'px';
        tooltipEl.style.top = positionY + tooltipModel.caretY + 'px';
        tooltipEl.style.fontFamily = tooltipModel.options.bodyFont.family;
        tooltipEl.style.fontSize = tooltipModel.options.bodyFont.size + 'px';
        tooltipEl.style.fontStyle = tooltipModel.options.bodyFont.style;
        tooltipEl.style.padding = tooltipModel.padding + 'px ' + tooltipModel.padding + 'px';
        tooltipEl.style.pointerEvents = 'none';
    }

    // Updates chart data and appearance based on the selected filters and settings
    updateChart() {
        if (!this.chart) {
            console.warn("Chart is not initialized yet.");
            return;
        }

        const dataMap = new Map();
        const labelsSet = new Set();
        const datasetsMap = new Map();
        const totalByMonth = new Map(); // New map to store totals for each month


        this.filteredData = this.displaySelected === 'location' ? this.data.filter(item => item.segmentation !== "Potential New Business" && item.opportunity == null ) : this.data;
        this.filteredData.forEach(item => {
            const xAxisValue = this.getXAxisValue(item);
            const yAxisValue = item[this.selectedYAxis];
            labelsSet.add(xAxisValue);

            if (!dataMap.has(xAxisValue)) {
                dataMap.set(xAxisValue, new Map());
            }

            // Accumulate total for each month
            totalByMonth.set(xAxisValue, (totalByMonth.get(xAxisValue) || 0) + yAxisValue);

            let temp = this.displaySelected === 'location' ? item.locationName : item.segmentation;

            const segmentData = dataMap.get(xAxisValue);
            segmentData.set(temp, (segmentData.get(temp) || 0) + yAxisValue);

            datasetsMap.set(temp, this.getRandomColor());
        });

        this.chart.data.labels = Array.from(labelsSet);
        this.chart.data.datasets = Array.from(datasetsMap.keys()).map(element => ({
            label: element,
            backgroundColor: datasetsMap.get(element),
            data: this.chart.data.labels.map(label => dataMap.get(label)?.get(element) || 0)
        }));

        // Pass the totalByMonth to your tooltip or label config to use it for the "out of" value
        this.chart.options.plugins.tooltip.callbacks.label = (tooltipItem) => {
            const datasetIndex = tooltipItem.datasetIndex;
            const index = tooltipItem.dataIndex;
            const value = parseInt(tooltipItem.dataset.data[index]);
            const formattedValue = value.toLocaleString('en-US');

            const xAxisValue = this.chart.data.labels[index];
            const monthTotal = parseInt(totalByMonth.get(xAxisValue));
            const formattedMonthTotal = monthTotal.toLocaleString('en-US');

            return `${this.displaySelected === 'segmentation' ? this.customLabels.segmentation : this.customLabels.location}: ${tooltipItem.dataset.label}
                    <br>${this.customLabels.date}: ${xAxisValue}
                    <br>${this.customLabels.revenue}: ${formattedValue} out of ${formattedMonthTotal}`;
        };


        this.chart.update();
    }


    getXAxisValue(item) {
        switch (this.selectedXAxis) {
            case 'month-year':
                return `${item.month}-${item.year}`;
            case 'location':
                return item.locationName;
            default:
                return '';
        }
    }

    getRandomColor() {
        const hexArray = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 'A', 'B', 'C', 'D', 'E', 'F'];
        let code = "";
        for (let i = 0; i < 6; i++) {
            code += hexArray[Math.floor(Math.random() * 16)];
        }
        return `#${code}`;
    }

    handleChartClick(evt) {
        const elements = this.chart.getElementsAtEventForMode(evt, 'nearest', { intersect: true });
        if (elements.length > 0) {
            const clickedElement = elements[0];
            const datasetIndex = clickedElement.datasetIndex;
            const index = clickedElement.index;

            const labelName = this.chart.data.datasets[datasetIndex].label;
            const xAxisValue = this.chart.data.labels[index];
            let temp = this.displaySelected == 'location' ?  'Location__r.Name' : 'Segmentation__c';

            this.selectedFilters ={
                'CALENDAR_MONTH(Start_date__c)' : parseInt(xAxisValue.split('-')[0]),
                'CALENDAR_YEAR(Start_date__c)' : parseInt(xAxisValue.split('-')[1]),
                [temp] : labelName
            };
            this.queryData();
        }
    }
    columns;

    queryData() {
        let whereClause = Object.keys(this.selectedFilters)
            .map(field => {
                if (typeof this.selectedFilters[field] === 'number') {
                    return `${field} = ${this.selectedFilters[field]}`;
                } else {
                    return `${field} = '${this.selectedFilters[field]}'`;
                }
            })
            .join(' AND ');

        queryMonthlyPayments({ whereClause  })
            .then(result => {
                console.log('queryMonthlyPayments = ', result );

                this.dataDetail = result;

                if (this.dataDetail.length > 0) {
                    this.isEmptyTable = false;
                    this.dataDetail = this.displaySelected === 'location' ? this.dataDetail.filter(item => item.Segmentation__c !== "Potential New Business" && item.Opportunity__c == null ) : result;
                    console.log('dataDetail = ', this.dataDetail );


                    const firstItem = this.dataDetail[0];
                    this.columns = Object.keys(firstItem);
                    const data = this.dataDetail.map(item => {
                        return this.columns.map(columnName => {
                            return this.safePropertyAccess(item, columnName);
                        });
                    });
                    this.dataToDisplay = data;
                    this.dataToDisplay = this.dataToDisplay.map(row => {
                        return row = row.map(value => {
                            const newRow = this.isSalesforceId(value) ?  `<a href="/${value}" target="_blank" data-id=${value}>${value}</a>` : `<p>${value}</p>`;
                            return newRow;
                        })

                    });
                }else{
                    this.isEmptyTable = true;
                }
                this.createTableBody(this.dataDetail);
            })
            .catch(error => {
                this.showToast('Error', error.message, 'error');
            });
    }


    createTableBody(data) {

        console.log('data createTableBody ' , JSON.stringify(data));


        const {
            mpTableContractType,
            mpTableDeskNumber,
            mpTableEndDate,
            mpTableFinalPrice,
            MPTableSegmentation,
            mpTableLocation,
            mpTableName,
            mpTableStartDate,
        } = this.customLabels;


        const columnFieldMap = {
            [mpTableName]: 'Name',
            [mpTableStartDate] : 'Start_date__c',
            [mpTableEndDate] : 'End_date__c',
            [mpTableDeskNumber] : 'Desk_Capacity__c',
            [mpTableContractType] : 'Contract__r.Type__c',
            [mpTableLocation] : 'Location__r.Name',
            [mpTableFinalPrice] : 'FinalPrice__c',
            [MPTableSegmentation] : 'Segmentation__c',
        };


        this.tableBody = data.map(item => {
            const row = this.columnsTable.map(columnName => {
                const fieldName = columnFieldMap[columnName];
                let cellData = this.safePropertyAccess(item, fieldName);

                // For the Name column, create a link to the record page
                if (columnName === 'Name') {
                    cellData = `<a href="/${item.Id}" target="_blank">${cellData}</a>`;
                } else if (this.isSalesforceId(cellData)) {
                    const nameField = fieldName.includes('Opportunity__r') ? 'Opportunity__r.Name' :
                                      fieldName.includes('Contract__r') ? 'Contract__r.Name' :
                                      fieldName.includes('Location__r') ? 'Location__r.Name' : null;

                    if (nameField) {
                        cellData = this.safePropertyAccess(item, nameField) || `<a href="/${cellData}" target="_blank" data-id=${cellData}>${cellData}</a>`;
                    }
                }

                return cellData;
            });

            return {
                id: item.Id,
                row: row
            };
        });

    }



    // safePropertyAccess(obj, prop) {
    //     let val = obj?.[prop] ?? '';
    //     if (typeof val === 'object') {
    //         val = JSON.stringify(val);
    //     }
    //     return val;
    // }
    safePropertyAccess(obj, prop) {
        try {
            // Split the property path by '.' to handle nested properties
            const propArray = prop.split('.');
            let value = obj;
            for (let p of propArray) {
                value = value?.[p] ?? ''; // Traverse through the nested properties
            }
            return value;
        } catch (e) {
            console.error(`Error accessing property ${prop} on object`, obj);
            return '';
        }
    }


    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
    redirectToRecord(ev){
        this[NavigationMixin.Navigate]({
            type: "standard__recordPage",
            attributes: {
              recordId: ev.target.dataset.id ,
              actionName: "view",
            },
          });
    }
    isSalesforceId(value) {
            const idPattern = /^[a-zA-Z0-9]{15}|[a-zA-Z0-9]{18}$/;
            const test = idPattern.test(value);
            return test;
    }

}