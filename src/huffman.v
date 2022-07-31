module huffman(clk, reset, gray_data, gray_valid, CNT_valid, CNT1, CNT2, CNT3, CNT4, CNT5, CNT6,
    code_valid, HC1, HC2, HC3, HC4, HC5, HC6, M1, M2, M3, M4, M5, M6);

input clk;
input reset;
input gray_valid;
input [7:0] gray_data;
output reg CNT_valid;
output [7:0] CNT1, CNT2, CNT3, CNT4, CNT5, CNT6;
output reg code_valid;
output [7:0] HC1, HC2, HC3, HC4, HC5, HC6;
output [7:0] M1, M2, M3, M4, M5, M6;

reg [7:0] HC[0:5];
reg [7:0] M[0:5];

reg [2:0] state;
reg [2:0] n_state;

reg [7:0] weight[0:5];
reg [6:0] symbol_temp[0:5];
reg [6:0] count;
reg [6:0] symbol[0:5];
reg [5:0] tree[0:3];
reg [6:0] tree_weight[0:3];
reg flag;
reg [2:0] sort_cnt;

reg [6:0] current_weight;
reg [5:0] current_tree;
reg [5:0] high;
reg [5:0] low;
reg [1:0] base_cnt;

reg [7:0] gray_data_temp;

parameter IDLE    = 0;
parameter INPUT   = 1;
parameter SORT    = 2;
parameter ENCODE  = 3;
parameter DECODE  = 4;
parameter OUT     = 5;

integer i;

// FSM
always @(posedge clk or posedge reset) begin
	if (reset) begin
		state <= IDLE;
	end
	else begin
		state <= n_state;
	end
end

// FSM next state assignment
always @(*) begin
	case(state)
		IDLE: begin
			if(gray_valid) n_state = INPUT;
			else n_state = state;
		end
		INPUT: begin
			if(count == 100) n_state = SORT;
			else n_state = state;
		end
		SORT: begin
			if(count == 5) n_state = ENCODE;
			else n_state = state;
		end
		ENCODE: begin
			if(count == 4) n_state = DECODE;
			else n_state = state;
		end
		DECODE: begin
			if(sort_cnt == 4) n_state = OUT;
			else n_state = state;
		end
		default: n_state = state;
	endcase
end

// sorting cnt
always @(posedge clk or posedge reset) begin
	if (reset) begin
		sort_cnt <= 0;
	end
	else begin
		case(state)
			SORT: sort_cnt <= (sort_cnt == 5)? 0 : (sort_cnt + 1);
			ENCODE: begin
				if (count == 4) begin
					sort_cnt <= 3;
				end
				else if (flag == 0) begin
					if(weight[count] + weight[count + 1] > weight[count + 2]) sort_cnt <= sort_cnt + 1;
					else sort_cnt <= 0;
				end
				else begin
					if(tree_weight[count] > weight[count + sort_cnt + 2]) sort_cnt <= sort_cnt + 1;
					else sort_cnt <= 0;
				end
			end
			DECODE: sort_cnt <= (sort_cnt == 0)? 5 : (sort_cnt - 1);
			default: sort_cnt <= sort_cnt;
		endcase
	end
end

always @(posedge clk or posedge reset) begin
	if (reset) begin
		gray_data_temp <= 0;
	end
	else begin
		gray_data_temp <= gray_data;
	end
end


// count prob of symbols
always @(posedge clk or posedge reset) begin
	if (reset) begin
		for(i = 0; i < 6; i = i + 1) begin
			weight[i] <= 0;
		end
	end
	else begin
		case(state)
			INPUT: begin
				case(gray_data_temp)
					6: weight[0] <= weight[0] + 1;
					5: weight[1] <= weight[1] + 1;
					4: weight[2] <= weight[2] + 1;
					3: weight[3] <= weight[3] + 1;
					2: weight[4] <= weight[4] + 1;
					1: weight[5] <= weight[5] + 1;
					default: begin
						for(i = 0; i < 6; i = i + 1) begin
							weight[i] <= weight[i];
						end
					end
				endcase
			end
			SORT: begin
				if (weight[sort_cnt[0]] > weight[sort_cnt[0] + 1]) begin
					weight[sort_cnt[0]] <= weight[sort_cnt[0] + 1];
					weight[sort_cnt[0] + 1] <= weight[sort_cnt[0]];
				end
				else begin
					weight[sort_cnt[0]] <= weight[sort_cnt[0]];
					weight[sort_cnt[0] + 1] <= weight[sort_cnt[0] + 1];
				end
				if (weight[sort_cnt[0] + 2] > weight[sort_cnt[0] + 3]) begin
					weight[sort_cnt[0] + 2] <= weight[sort_cnt[0] + 3];
					weight[sort_cnt[0] + 3] <= weight[sort_cnt[0] + 2];
				end
				else begin
					weight[sort_cnt[0] + 2] <= weight[sort_cnt[0] + 2];
					weight[sort_cnt[0] + 3] <= weight[sort_cnt[0] + 3];
				end
				if (weight[sort_cnt[0] + 4] > weight[sort_cnt[0] + 5]) begin
					weight[sort_cnt[0] + 4] <= weight[sort_cnt[0] + 5];
					weight[sort_cnt[0] + 5] <= weight[sort_cnt[0] + 4];
				end
				else begin
					weight[sort_cnt[0] + 4] <= weight[sort_cnt[0] + 4];
					weight[sort_cnt[0] + 5] <= weight[sort_cnt[0] + 5];
				end
			end
			ENCODE: begin
				if(flag == 1) begin
					if(weight[count + sort_cnt] > weight[count + 1 + sort_cnt]) begin
						weight[count + sort_cnt] <= weight[count + 1 + sort_cnt];
						weight[count + 1 + sort_cnt] <= weight[count + sort_cnt];
					end
					else begin
						weight[count + 1 + sort_cnt] <= weight[count + 1 + sort_cnt];
						weight[count + 2 + sort_cnt] <= weight[count + 2 + sort_cnt];
					end
				end
				else begin
					weight[count + 1] <= weight[count] + weight[count + 1];
				end
			end
			default: begin
				for(i = 0; i < 6; i = i + 1) begin
					weight[i] <= weight[i];
				end
			end
		endcase
	end
end

// symbols, symbol_1 = 000001
always @(posedge clk or posedge reset) begin
	if (reset) begin
		symbol[5] <= 6'b000001;
		symbol[4] <= 6'b000010;
		symbol[3] <= 6'b000100;
		symbol[2] <= 6'b001000;
		symbol[1] <= 6'b010000;
		symbol[0] <= 6'b100000;
	end
	else begin
		case(state)
			SORT: begin
				if (weight[sort_cnt[0]] > weight[sort_cnt[0] + 1]) begin
					symbol[sort_cnt[0]] <= symbol[sort_cnt[0] + 1];
					symbol[sort_cnt[0] + 1] <= symbol[sort_cnt[0]];
				end
				else begin
					symbol[sort_cnt[0]] <= symbol[sort_cnt[0]];
					symbol[sort_cnt[0] + 1] <= symbol[sort_cnt[0] + 1];
				end
				if (weight[sort_cnt[0] + 2] > weight[sort_cnt[0] + 3]) begin
					symbol[sort_cnt[0] + 2] <= symbol[sort_cnt[0] + 3];
					symbol[sort_cnt[0] + 3] <= symbol[sort_cnt[0] + 2];
				end
				else begin
					symbol[sort_cnt[0] + 2] <= symbol[sort_cnt[0] + 2];
					symbol[sort_cnt[0] + 3] <= symbol[sort_cnt[0] + 3];
				end
				if (sort_cnt[0] == 1) begin
					symbol[sort_cnt[0] + 4] <= symbol[sort_cnt[0] + 4];
				end
				else begin
					if (weight[sort_cnt[0] + 4] > weight[sort_cnt[0] + 5]) begin
						symbol[sort_cnt[0] + 4] <= symbol[sort_cnt[0] + 5];
						symbol[sort_cnt[0] + 5] <= symbol[sort_cnt[0] + 4];
					end
					else begin
						symbol[sort_cnt[0] + 4] <= symbol[sort_cnt[0] + 4];
						symbol[sort_cnt[0] + 5] <= symbol[sort_cnt[0] + 5];
					end
				end
			end
			ENCODE: begin
				if(flag == 1) begin
					if(weight[count + sort_cnt] > weight[count + 1 + sort_cnt]) begin
						symbol[count + sort_cnt] <= symbol[count + 1 + sort_cnt];
						symbol[count + 1 + sort_cnt] <= symbol[count + sort_cnt];
					end
					else begin
						symbol[count + 1 + sort_cnt] <= symbol[count + 1 + sort_cnt];
						symbol[count + 2 + sort_cnt] <= symbol[count + 2 + sort_cnt];
					end
				end
				else begin
					symbol[count + 1] <= symbol[count] + symbol[count + 1];
				end
			end
			default: begin
				for(i = 0; i < 6; i = i + 1) begin
					symbol[i] <= symbol[i];
				end
			end
		endcase
	end
end

// store symbols that sorted
always @(posedge clk or posedge reset) begin
	if (reset) begin
		for(i = 0; i < 6; i = i + 1) begin
			symbol_temp[i] <= 0;
		end
	end
	else begin
		case(state)
			SORT: begin
				for(i = 0; i < 6; i = i + 1) begin
					symbol_temp[i] <= symbol[i];
				end
			end
			default: begin
				for(i = 0; i < 6; i = i + 1) begin
					symbol_temp[i] <= symbol_temp[i];
				end
			end
		endcase
	end
end

always @(posedge clk or posedge reset) begin
	if (reset) begin
		count <= 0;
	end
	else begin
		case(state)
			INPUT: count <= (count == 100)? 0 : (count + 1);
			SORT: count <= (count == 5)? 0 : (count + 1);
			ENCODE: begin
				if (flag == 0) begin
					if(weight[count] + weight[count + 1] > weight[count + 2]) count <= count;
					else count <= count + 1;
				end
				else begin
					if(tree_weight[count] > weight[count + sort_cnt + 2]) count <= count;
					else count <= count + 1;
				end
			end
			default: count <= count;
		endcase
	end
end

always @(posedge clk or posedge reset) begin
	if (reset) begin
		CNT_valid <= 0;
	end
	else begin
		if(count == 100 && state == INPUT) CNT_valid <= 1;
		else CNT_valid <= 0;
	end
end

assign CNT6 = weight[0];
assign CNT5 = weight[1];
assign CNT4 = weight[2];
assign CNT3 = weight[3];
assign CNT2 = weight[4];
assign CNT1 = weight[5];

// flag for encode sorting
always @(posedge clk or posedge reset) begin
	if (reset) begin
		flag <= 0;
	end
	else begin
		case(state)
			ENCODE: begin
				if (flag == 0) begin
					if(weight[count] + weight[count + 1] > weight[count + 2]) flag <= 1;
					else flag <= flag;
				end
				else begin
					if(tree_weight[count] > weight[count + sort_cnt + 2]) flag <= flag;
					else flag <= 0;
				end
			end
			default: flag <= flag;
		endcase
	end
end

// base binary tree count
always @(posedge clk or posedge reset) begin
	if (reset) begin
		base_cnt <= 0;
	end
	else begin
		case(state)
			ENCODE: begin
				if(sort_cnt == 2) base_cnt <= base_cnt + 1;
				else base_cnt <= base_cnt;
			end
			DECODE: begin
				if (current_tree[0] + current_tree[1] + current_tree[2] + current_tree[3] + current_tree[4] + current_tree[5] == 2) base_cnt <= base_cnt - 1;
				else base_cnt <= base_cnt;
			end
			default: base_cnt <= base_cnt;
		endcase
	end
end

// binary tree
always @(posedge clk or posedge reset) begin
	if (reset) begin
		for(i = 0; i < 4; i = i + 1) begin
			tree[i] <= 0;
		end
	end
	else begin
		case(state)
			ENCODE: begin
				tree[count] <= (flag == 0)? ( symbol[count] + symbol[count + 1] ) : tree[count];
			end
			default: begin
				for(i = 0; i < 4; i = i + 1) begin
					tree[i] <= tree[i];
				end
			end
		endcase
	end
end

// weight of binary tree
always @(posedge clk or posedge reset) begin
	if (reset) begin
		for(i = 0; i < 4; i = i + 1) begin
			tree_weight[i] <= 0;
		end
	end
	else begin
		case(state)
			ENCODE: begin
				tree_weight[count] <= (flag == 0)? ( weight[count] + weight[count + 1] ) : tree_weight[count];
			end
			default: begin
				for(i = 0; i < 4; i = i + 1) begin
					tree_weight[i] <= tree_weight[i];
				end
			end
		endcase
	end
end

always @(posedge clk or posedge reset) begin
	if (reset) begin
		current_weight <= 7'd100;
	end
	else begin
		case(state)
			DECODE: begin
				current_weight <= (sort_cnt == 5)? 0 : (tree_weight[sort_cnt]);
			end
			default: current_weight <= current_weight;
		endcase
	end
end

always @(posedge clk or posedge reset) begin
	if (reset) begin
		current_tree <= 6'b111111;
	end
	else begin
		case(state)
			DECODE: begin
				current_tree <= (sort_cnt == 5)? 0 : (tree[sort_cnt]);
			end
			default: current_tree <= current_tree;
		endcase
	end
end

// binary tree lower weight side
always @(posedge clk or posedge reset) begin
	if (reset) begin
		low <= 0;
	end
	else begin
		case(state)
			DECODE: begin
				if (current_tree[0] + current_tree[1] + current_tree[2] + current_tree[3] + current_tree[4] + current_tree[5] == 2) begin
					low <= symbol_temp[ ( base_cnt << 1 ) ];
				end
				else begin
					if (current_weight - tree_weight[sort_cnt] < tree_weight[sort_cnt]) begin
						low <= (sort_cnt == 5)? 0 : (current_tree ^ tree[sort_cnt]);
					end
					else begin
						low <= (sort_cnt == 5)? 0 : (tree[sort_cnt]);
					end
				end
			end
			default: low <= low;
		endcase
	end
end

// binary tree greater weight side
always @(posedge clk or posedge reset) begin
	if (reset) begin
		high <= 0;
	end
	else begin
		case(state)
			DECODE: begin
				if (current_tree[0] + current_tree[1] + current_tree[2] + current_tree[3] + current_tree[4] + current_tree[5] == 2) begin
					high <= symbol_temp[ ( base_cnt << 1 ) + 1 ];
				end
				else begin
					if (current_weight - tree_weight[sort_cnt] < tree_weight[sort_cnt]) begin
						high <= (sort_cnt == 5)? 0 : (tree[sort_cnt]);
					end
					else begin
						high <= (sort_cnt == 5)? 0 : (current_tree ^ tree[sort_cnt]);
					end
				end
			end
			default: high <= high;
		endcase
	end
end

// Huffman code
always @(posedge clk or posedge reset) begin
	if (reset) begin
		for(i = 0; i < 6; i = i + 1) begin
			HC[i] <= 0;
		end
	end
	else begin
		case(state)
			DECODE: begin
				if(low[0] == 1) HC[0] <= ( HC[0] << 1 ) + 1;
				else if(high[0] == 1) HC[0] <= ( HC[0] << 1 );
				else HC[0] <= HC[0];
				if(low[1] == 1) HC[1] <= ( HC[1] << 1 ) + 1;
				else if(high[1] == 1) HC[1] <= ( HC[1] << 1 );
				else HC[1] <= HC[1];
				if(low[2] == 1) HC[2] <= ( HC[2] << 1 ) + 1;
				else if(high[2] == 1) HC[2] <= ( HC[2] << 1 );
				else HC[2] <= HC[2];
				if(low[3] == 1) HC[3] <= ( HC[3] << 1 ) + 1;
				else if(high[3] == 1) HC[3] <= ( HC[3] << 1 );
				else HC[3] <= HC[3];
				if(low[4] == 1) HC[4] <= ( HC[4] << 1 ) + 1;
				else if(high[4] == 1) HC[4] <= ( HC[4] << 1 );
				else HC[4] <= HC[4];
				if(low[5] == 1) HC[5] <= ( HC[5] << 1 ) + 1;
				else if(high[5] == 1) HC[5] <= ( HC[5] << 1 );
				else HC[5] <= HC[5];
			end
			default: begin
				for(i = 0; i < 6; i = i + 1) begin
					HC[i] <= HC[i];
				end
			end
		endcase
	end
end

assign HC1 = HC[0];
assign HC2 = HC[1];
assign HC3 = HC[2];
assign HC4 = HC[3];
assign HC5 = HC[4];
assign HC6 = HC[5];

// Mask
always @(posedge clk or posedge reset) begin
	if (reset) begin
		for(i = 0; i < 6; i = i + 1) begin
			M[i] <= 0;
		end
	end
	else begin
		case(state)
			DECODE: begin
				if(low[0] == 1) M[0] <= ( M[0] << 1 ) + 1;
				else if(high[0] == 1)M[0] <= ( M[0] << 1 ) + 1;
				else M[0] <= M[0];
				if(low[1] == 1) M[1] <= ( M[1] << 1 ) + 1;
				else if(high[1] == 1) M[1] <= ( M[1] << 1 ) + 1;
				else M[1] <= M[1];
				if(low[2] == 1) M[2] <= ( M[2] << 1 ) + 1;
				else if(high[2] == 1) M[2] <= ( M[2] << 1 ) + 1;
				else M[2] <= M[2];
				if(low[3] == 1) M[3] <= ( M[3] << 1 ) + 1;
				else if(high[3] == 1) M[3] <= ( M[3] << 1 ) + 1;
				else M[3] <= M[3];
				if(low[4] == 1) M[4] <= ( M[4] << 1 ) + 1;
				else if(high[4] == 1) M[4] <= ( M[4] << 1 ) + 1;
				else M[4] <= M[4];
				if(low[5] == 1) M[5] <= ( M[5] << 1 ) + 1;
				else if(high[5] == 1) M[5] <= ( M[5] << 1 ) + 1;
				else M[5] <= M[5];
			end
			default: begin
				for(i = 0; i < 6; i = i + 1) begin
					M[i] <= M[i];
				end
			end
		endcase
	end
end

assign M1 = M[0];
assign M2 = M[1];
assign M3 = M[2];
assign M4 = M[3];
assign M5 = M[4];
assign M6 = M[5];

always @(posedge clk or posedge reset) begin
	if (reset) begin
		code_valid <= 0;
	end
	else begin
		case(state)
			OUT: code_valid <= 1;
			default: code_valid <= code_valid;		
		endcase
	end
end

endmodule

